import React, { PropTypes } from 'react';
export default class Checkbox extends React.Component {
  render() {
    let {
      label,
      name,
      value
    } = this.props;

    return <div className="cf-form-checkboxes">
      <div className="cf-form-checkbox">

      <input
        name={name}
        onChange={this.props.onChange}
        type="checkbox"
        id={name}
        checked={value}
      />
      <label className="question-label" htmlFor={name}>{label || name}</label>
      </div>
    </div>;
  }
}

Checkbox.propTypes = {
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  value: PropTypes.bool
};
