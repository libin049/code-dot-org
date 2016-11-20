/* FilterSet: The overall search area in TutorialExplorer.  Contains a set of filter groups.
 */

import React from 'react';
import FilterGroup from './filterGroup';
import RoboticsButton from './roboticsButton';

const FilterSet = React.createClass({
  propTypes: {
    filterGroups: React.PropTypes.array.isRequired,
    onUserInput: React.PropTypes.func.isRequired,
    selection: React.PropTypes.objectOf(React.PropTypes.arrayOf(React.PropTypes.string)).isRequired,
    mobileLayout: React.PropTypes.bool.isRequired,
    roboticsButtonUrl: React.PropTypes.string
  },

  componentDidMount() {
    if (this.props.mobileLayout) {
      $('html, body').animate({
        scrollTop: $("#filterset").offset().top - $("#filterheader").height() - 6
      }, 1000);
    }
  },

  render() {
    return (
      <div id="filterset">
        {this.props.filterGroups.map(item =>
          item.display !== false && (
            <FilterGroup
              name={item.name}
              text={item.text}
              filterEntries={item.entries}
              onUserInput={this.props.onUserInput}
              selection={this.props.selection[item.name]}
              key={item.name}
            />
          )
        )}

        {this.props.roboticsButtonUrl && (
          <RoboticsButton url={this.props.roboticsButtonUrl}/>
        )}

      </div>
    );
  }
});

export default FilterSet;
