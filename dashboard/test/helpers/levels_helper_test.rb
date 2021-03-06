require 'test_helper'

class LevelsHelperTest < ActionView::TestCase
  include Devise::Test::ControllerHelpers

  def sign_in(user)
    # override the default sign_in helper because we don't actually have a request or anything here
    stubs(:current_user).returns user
  end

  setup do
    @level = create(:maze, level_num: 'custom')

    def request
      OpenStruct.new(
        env: {},
        headers: OpenStruct.new('User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36')
      )
    end

    stubs(:current_user).returns nil
  end

  test "blockly_options refuses to generate options for non-blockly levels" do
    @level = create(:match)
    assert_raises(ArgumentError) do
      blockly_options
    end
  end

  test "should parse maze level with non string array" do
    @level.properties["maze"] = [[0, 0], [2, 3]]
    options = blockly_options
    assert options[:level]["map"].is_a?(Array), "Maze is not an array"

    reset_view_options

    @level.properties["maze"] = @level.properties["maze"].to_s
    options = blockly_options
    assert options[:level]["map"].is_a?(Array), "Maze is not an array"
  end

  test "non-custom level displays localized instruction after locale switch" do
    default_locale = 'en-US'
    new_locale = 'es-ES'
    @level.instructions = nil
    @level.user_id = nil
    @level.level_num = '2_2'

    I18n.locale = default_locale
    options = blockly_options
    assert_equal I18n.t('data.level.instructions.maze_2_2', locale: default_locale), options[:level]['instructions']

    reset_view_options

    I18n.locale = new_locale
    options = blockly_options
    assert_equal I18n.t('data.level.instructions.maze_2_2', locale: new_locale), options[:level]['instructions']
  end

  test "custom level displays english instruction" do
    default_locale = 'en-US'
    @level = Level.find_by_name 'frozen line'

    I18n.locale = default_locale
    options = blockly_options
    assert_equal @level.instructions, options[:level]['instructions']
  end

  test "custom level displays localized instruction if exists" do
    new_locale = 'es-ES'

    I18n.locale = new_locale
    @level = Level.find_by_name 'frozen line'
    options = blockly_options
    assert_equal I18n.t("data.instructions.#{@level.name}_instruction", locale: new_locale), options[:level]['instructions']

    reset_view_options

    @level.name = 'this_level_doesnt_exist'
    options = blockly_options
    assert_equal @level.instructions, options[:level]['instructions']
  end

  test "get video choices" do
    choices_cached = video_key_choices
    assert_equal(choices_cached.count, Video.count)
    Video.all.each {|video| assert_includes(choices_cached, video.key)}
  end

  test "blockly options converts 'impressive' => 'false' to 'impressive => false'" do
    @level = create :artist
    @stage = create :stage
    @script_level = create :script_level, levels: [@level], stage: @stage
    @level.impressive = "false"
    @level.free_play = "false"

    options = blockly_options

    assert_equal false, options[:level]['impressive']
    assert_equal false, options[:level]['freePlay']
  end

  test "custom callouts" do
    @level.level_num = 'custom'
    @level.callout_json = '[{"localization_key": "run", "element_id": "#runButton"}]'

    callouts = select_and_remember_callouts
    assert_equal 1, callouts.count
    assert_equal '#runButton', callouts[0]['element_id']
    assert_equal 'Hit "Run" to try your program', callouts[0]['localized_text']

    callouts = select_and_remember_callouts
    assert_equal 0, callouts.count
  end

  test "should select only callouts for current script level" do
    script = create(:script)
    @level = create(:level, :blockly, user_id: nil)
    stage = create(:stage, script: script)
    @script_level = create(:script_level, script: script, levels: [@level], stage: stage)

    callout1 = create(:callout, script_level: @script_level)
    callout2 = create(:callout, script_level: @script_level)
    irrelevant_callout = create(:callout)

    callouts = select_and_remember_callouts

    assert callouts.any? {|callout| callout['id'] == callout1.id}
    assert callouts.any? {|callout| callout['id'] == callout2.id}
    assert callouts.none? {|callout| callout['id'] == irrelevant_callout.id}
  end

  test "should localize callouts" do
    script = create(:script)
    @level = create(:level, :blockly, user_id: nil)
    stage = create(:stage, script: script)
    @script_level = create(:script_level, script: script, levels: [@level], stage: stage)

    create(:callout, script_level: @script_level, localization_key: 'run')

    callouts = select_and_remember_callouts

    assert callouts.any? {|c| c['localized_text'] == 'Hit "Run" to try your program'}
  end

  test 'app_options returns camelCased view option on Blockly level' do
    @level.start_blocks = '<test/>'
    options = app_options
    assert_equal '<test/>', options[:level]['startBlocks']
  end

  test "embedded-freeplay level doesn't remove header and footer" do
    @level.embed = true
    app_options
    assert_nil view_options[:no_header]
    assert_nil view_options[:no_footer]
  end

  test 'Blockly#blockly_app_options and Blockly#blockly_level_options not modified by levels helper' do
    level = create(:level, :blockly, :with_autoplay_video)
    blockly_app_options = level.blockly_app_options level.game, level.skin
    blockly_level_options = level.blockly_level_options

    @level = level
    app_options

    assert_equal blockly_app_options, level.blockly_app_options(level.game, level.skin)
    assert_equal blockly_level_options, level.blockly_level_options
  end

  test 'app_options sets a channel' do
    user = create :user
    sign_in user

    channel = get_channel_for(@level)
    # Request it again, should get the same channel
    assert_equal channel, get_channel_for(@level)

    # Request it for a different level, should get a different channel
    level = create(:level, :blockly)
    assert_not_equal channel, get_channel_for(level)
  end

  test 'applab levels should have channels' do
    user = create :user
    sign_in user

    @level = create :applab
    assert_not_nil app_options['channel']
  end

  test 'applab levels should not load channel when viewing student solution of a student without a channel' do
    # two different users
    @user = create :user
    sign_in create(:user)

    @level = create :applab

    # channel does not exist
    assert_nil get_channel_for(@level, @user)
  end

  test 'applab levels should load channel when viewing student solution of a student with a channel' do
    # two different users
    @user = create :user
    sign_in create(:user)

    @level = create :applab

    # channel exists
    ChannelToken.create!(level: @level, user: @user, channel: 'whatever')
    assert_equal 'whatever', get_channel_for(@level, @user)
  end

  def stub_country(code)
    req = request
    req.location = OpenStruct.new country_code: code
    stubs(:request).returns(req)
  end

  test 'send to phone enabled for US' do
    stub_country 'US'
    assert app_options[:sendToPhone]
  end

  test 'send to phone disabled for non-US' do
    stub_country 'RU'
    refute app_options[:sendToPhone]
  end

  test 'send_to_phone_url provided when send to phone enabled' do
    stub_country 'US'
    assert_equal 'http://test.host/sms/send', app_options[:send_to_phone_url]
  end

  test 'submittable level is submittable for teacher enrolled in plc' do
    @level = create(:free_response, submittable: true, peer_reviewable: 'true')
    Plc::UserCourseEnrollment.stubs(:exists?).returns(true)

    user = create(:teacher)
    sign_in user

    app_options = question_options

    assert_equal true, app_options[:level]['submittable']
  end

  test 'submittable level is not submittable for a teacher not enrolled in plc' do
    @level = create(:free_response, submittable: true, peer_reviewable: 'true')
    Plc::UserCourseEnrollment.stubs(:exists?).returns(false)

    user = create(:teacher)
    sign_in user

    app_options = question_options

    assert_not app_options[:level]['submittable']
  end

  test 'submittable level is submittable for student with teacher' do
    @level = create(:applab, submittable: true)

    user = create(:follower).student_user
    sign_in user

    assert_equal true, app_options[:level]['submittable']
  end

  test 'submittable level is not submittable for student without teacher' do
    @level = create(:applab, submittable: true)

    user = create :student
    sign_in user

    assert_equal false, app_options[:level]['submittable']
  end

  test 'submittable level is not submittable for non-logged in user' do
    @level = create(:applab, submittable: true)

    assert_equal false, app_options[:level]['submittable']
  end

  test 'submittable multi level is submittable for student with teacher' do
    @level = create(:multi, submittable: true)

    user = create(:follower).student_user
    sign_in user

    assert_equal true, app_options[:level]['submittable']
  end

  test 'submittable multi level is not submittable for student without teacher' do
    @level = create(:multi, submittable: true)

    user = create :student
    sign_in user

    assert_equal false, app_options[:level]['submittable']
  end

  test 'submittable multi level is not submittable for non-logged in user' do
    @level = create(:multi, submittable: true)

    assert_equal false, app_options[:level]['submittable']
  end

  test 'show solution link shows link for appropriate courses' do
    user = create :teacher
    sign_in user

    @level = create(:level, :blockly, :with_ideal_level_source)
    @script = create(:script)
    @script.update(professional_learning_course: 'Professional Learning Course')
    @script_level = create(:script_level, levels: [@level], script: @script)
    assert_not can_view_solution?

    sign_out user
    user = create :levelbuilder
    sign_in user
    assert can_view_solution?

    @script.update(name: 'algebra')
    assert_not can_view_solution?

    @script.update(name: 'some pd script')
    @script_level = nil
    assert_not can_view_solution?

    @script_level = create(:script_level, levels: [@level], script: @script)
    @level.update(ideal_level_source_id: nil)
    assert_not can_view_solution?
  end

  test 'show solution link shows link for appropriate users' do
    @level = create(:level, :blockly, :with_ideal_level_source)
    @script = create(:script)
    @script_level = create(:script_level, levels: [@level], script: @script)

    user = create :levelbuilder
    sign_in user
    assert can_view_solution?

    sign_out user
    user = create :teacher
    sign_in user
    assert can_view_solution?

    sign_out user
    user = create :student
    sign_in user
    assert_not can_view_solution?

    sign_out user
    assert_not can_view_solution?
  end

  test 'build_script_level_path differentiates lockable and non-lockable' do
    # (position 1) Lockable 1
    # (position 2) Non-Lockable 1
    # (position 3) Lockable 2
    # (position 4) Lockable 3
    # (position 5) Non-Lockable 2

    input_dsl = <<-DSL.gsub(/^\s+/, '')
      stage 'Lockable1',
        lockable: true;
      assessment 'LockableAssessment1';

      stage 'Nonockable1'
      assessment 'NonLockableAssessment1';

      stage 'Lockable2',
        lockable: true;
      assessment 'LockableAssessment2';

      stage 'Lockable3',
        lockable: true;
      assessment 'LockableAssessment3';

      stage 'Nonockable2'
      assessment 'NonLockableAssessment2';
    DSL

    create :level, name: 'LockableAssessment1'
    create :level, name: 'NonLockableAssessment1'
    create :level, name: 'LockableAssessment2'
    create :level, name: 'LockableAssessment3'
    create :level, name: 'NonLockableAssessment2'

    script_data, _ = ScriptDSL.parse(input_dsl, 'a filename')

    script = Script.add_script(
      {name: 'test_script'},
      script_data[:stages].map {|stage| stage[:scriptlevels]}.flatten
    )

    stage = script.stages[0]
    assert_equal 1, stage.absolute_position
    assert_equal 1, stage.relative_position
    assert_equal '/s/test_script/lockable/1/puzzle/1', build_script_level_path(stage.script_levels[0], {})
    assert_equal '/s/test_script/lockable/1/puzzle/1/page/1', build_script_level_path(stage.script_levels[0], {puzzle_page: '1'})

    stage = script.stages[1]
    assert_equal 2, stage.absolute_position
    assert_equal 1, stage.relative_position
    assert_equal '/s/test_script/stage/1/puzzle/1', build_script_level_path(stage.script_levels[0], {})
    assert_equal '/s/test_script/stage/1/puzzle/1/page/1', build_script_level_path(stage.script_levels[0], {puzzle_page: '1'})

    stage = script.stages[2]
    assert_equal 3, stage.absolute_position
    assert_equal 2, stage.relative_position
    assert_equal '/s/test_script/lockable/2/puzzle/1', build_script_level_path(stage.script_levels[0], {})
    assert_equal '/s/test_script/lockable/2/puzzle/1/page/1', build_script_level_path(stage.script_levels[0], {puzzle_page: '1'})

    stage = script.stages[3]
    assert_equal 4, stage.absolute_position
    assert_equal 3, stage.relative_position
    assert_equal '/s/test_script/lockable/3/puzzle/1', build_script_level_path(stage.script_levels[0], {})
    assert_equal '/s/test_script/lockable/3/puzzle/1/page/1', build_script_level_path(stage.script_levels[0], {puzzle_page: '1'})

    stage = script.stages[4]
    assert_equal 5, stage.absolute_position
    assert_equal 2, stage.relative_position
    assert_equal '/s/test_script/stage/2/puzzle/1', build_script_level_path(stage.script_levels[0], {})
    assert_equal '/s/test_script/stage/2/puzzle/1/page/1', build_script_level_path(stage.script_levels[0], {puzzle_page: '1'})
  end

  test 'standalone multi should include answers for student' do
    sign_in create(:student)

    @script = create(:script)
    @level = create :multi
    @stage = create :stage
    @script_level = create :script_level, levels: [@level], stage: @stage

    @user_level = create :user_level, user: current_user, best_result: 20, script: @script, level: @level

    standalone = true
    assert include_multi_answers?(standalone)
  end

  test 'non-standalone multi should not include answers for student' do
    sign_in create(:student)

    @script = create(:script)
    @level = create :multi
    @stage = create :stage
    @script_level = create :script_level, levels: [@level], stage: @stage

    @user_level = create :user_level, user: current_user, best_result: 20, script: @script, level: @level

    standalone = false
    assert_not include_multi_answers?(standalone)
  end

  test 'section first_activity_at should not be nil when finding experiments' do
    Experiment.stubs(:should_cache?).returns true
    teacher = create(:teacher)
    experiment = create(:teacher_based_experiment,
      earliest_section_at: DateTime.now - 1.day,
      latest_section_at: DateTime.now + 1.day,
      percentage: 100,
    )
    Experiment.update_cache
    section = create(:section, user: teacher)
    student = create(:student)
    section.add_student(student)

    sign_in student

    assert_includes app_options[:experiments], experiment.name
  end
end
