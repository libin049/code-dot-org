import React, { PropTypes } from 'react';
import _ from 'lodash';

const styles = {
  stageName: {
    fontSize: 16,
    textDecoration: 'underline'
  },
  inputUpdate: {
    backgroundColor: 'lightgreen'
  }
};

/**
 * Shows a list of stages that have descriptions, along with those descriptions.
 * If you click the import button, it grabs new descriptions from curriculum
 * builder and shows both sets.
 */
const StageDescriptions = React.createClass({
  propTypes: {
    isImporting: PropTypes.bool.isRequired,
    currentByStage: PropTypes.objectOf(
      PropTypes.shape({
        studentDescription: PropTypes.string.isRequired,
        teacherDescription: PropTypes.string.isRequired,
      })
    ).isRequired,
    importedByStage: PropTypes.objectOf(
      PropTypes.shape({
        studentDescription: PropTypes.string.isRequired,
        teacherDescription: PropTypes.string.isRequired,
      })
    ).isRequired,
    inputStyle: PropTypes.object.isRequired,
  },

  render() {
    const { isImporting, inputStyle, currentByStage, importedByStage } = this.props;

    const stageNames = _.uniq(Object.keys(currentByStage).concat(Object.keys(importedByStage)));

    return (
      <div>
        <h3>Stage Descriptions</h3>
        <div>Note: We only show info for stages that have descriptions</div>
        {stageNames.map((stageName, index) => {
          const currentStudent = (currentByStage[stageName] || {}).studentDescription;
          const currentTeacher = (currentByStage[stageName] || {}).teacherDescription;
          const updatedStudent = (importedByStage[stageName] || {}).studentDescription;
          const updatedTeacher = (importedByStage[stageName] || {}).teacherDescription;

          if (!currentStudent && !currentTeacher && !updatedStudent && !updatedTeacher) {
            // show nothing if we have nothing
            return;
          }

          return (
            <div key={index}>
              <div style={styles.stageName}>{stageName}</div>
              <label>
                Current Student Description
                <input
                  defaultValue={currentStudent}
                  style={inputStyle}
                  readOnly
                />
              </label>
              {importedByStage[stageName] &&
                <label>
                  Updated Student Description
                  <input
                    defaultValue={updatedStudent}
                    style={{...inputStyle, ...styles.inputUpdate}}
                    readOnly
                  />
                </label>
              }
              <label>
                Current Teacher Description
                <input
                  defaultValue={currentTeacher}
                  style={inputStyle}
                  readOnly
                />
              </label>
              {importedByStage[stageName] &&
                <label>
                  Updated Teacher Description
                  <input
                    defaultValue={updatedTeacher}
                    style={{...inputStyle, ...styles.inputUpdate}}
                    readOnly
                  />
                </label>
              }
            </div>
          );
        })}
        <button>
          {isImporting ? "Querying server..." : "Import from Curriculum Builder"}
        </button>
      </div>
    );
  }
});

export default StageDescriptions;
