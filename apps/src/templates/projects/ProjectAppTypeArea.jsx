import React, {PropTypes} from 'react';
import ProjectCard from './ProjectCard';
import {projectPropType} from './projectConstants';
import color from "../../util/color";

const styles = {
  grid: {
    padding: 10,
    width: 1000
  },
  card: {
    display: "inline-block",
    padding: 10
  },
  labHeading: {
    textAlign: "left",
    fontSize: 24,
    color: color.charcoal,
    marginLeft: 10,
    marginRight: 50,
    paddingBottom: 10,
    paddingTop: 40,
    float: 'left'
  },
  viewMore: {
    color: color.light_teal,
    float: 'right',
    marginTop: 75,
    cursor: 'pointer'
  }
};

const ProjectAppTypeArea = React.createClass({
  propTypes: {
    labName: PropTypes.string.isRequired,
    labViewMoreString: PropTypes.string.isRequired,
    projectList: PropTypes.arrayOf(projectPropType),
    numProjectsToShow: PropTypes.number.isRequired,
    galleryType: PropTypes.oneOf(['personal', 'class', 'public']).isRequired,
    navigateFunction: PropTypes.func.isRequired
  },

  viewMore() {
    const appName = this.props.labName.toLowerCase().replace(' ', '');
    this.props.navigateFunction(appName);
  },

  renderProjectCardList(projectList, max) {
    const { galleryType } = this.props;
    return  (
      <div>
        {
          projectList && projectList.slice(0,max).map((project, index) => (
            <div key={index} style={styles.card}>
              <ProjectCard
                projectData={project.projectData}
                currentGallery={galleryType}
              />
            </div>
          ))
        }
      </div>
    );
  },

  render() {
    return (
      <div style={styles.grid}>
        <h2 style={styles.labHeading}> {this.props.labName} </h2>
        <span style={styles.viewMore} onClick={this.viewMore}> {this.props.labViewMoreString} </span>
        <div style={{clear: 'both'}}></div>
        {this.renderProjectCardList(this.props.projectList, this.props.numProjectsToShow)}
      </div>
    );
  }
});

export default ProjectAppTypeArea;
