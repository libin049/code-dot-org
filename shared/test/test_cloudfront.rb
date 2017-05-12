require_relative 'test_helper'
require 'cdo/aws/cloudfront'

class TestCloudFront < Minitest::Test
  # Ensures that the cache configuration does not exceed CloudFront distribution limits.
  # 50 Cache behaviors per distribution (Updated from 25 through special request).
  # Ref: http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_cloudfront
  def test_cloudfront_limits
    %i(pegasus dashboard).each do |app|
      # +1 to include the default cache behavior in the count.
      behavior_count = AWS::CloudFront.config_cloudformation(app)[:CacheBehaviors].length + 1
      assert behavior_count <= 50, "#{app} has #{behavior_count} cache behaviors (max is 50)"
    end
  end
end
