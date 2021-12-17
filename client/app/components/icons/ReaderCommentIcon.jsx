import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

// used in CommentIcon.jsx

export const ReaderCommentIcon = (props) => {

  const { selected, id, size, className, color } = props;

  const filter = selected ? `url(#${id}-filter-1)` : '';

  return <svg height={size} viewBox="0 0 46 48" xmlns="http://www.w3.org/2000/svg" className={className}>
    <defs>
      <filter x="-13.8%" y="-8.8%" width="127.5%" height="127.5%" filterUnits="objectBoundingBox" id={`${id}-filter-1`}>
        <feOffset dx="0" dy="2" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
        <feGaussianBlur stdDeviation="1.5" in="shadowOffsetOuter1" result="shadowBlurOuter1"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 0.0313725509   0 0 0 0 0.447058827
        0 0 0 0 0.725490212  0 0 0 1 0" type="matrix" in="shadowBlurOuter1" result="shadowMatrixOuter1"></feColorMatrix>
        <feMerge>
          <feMergeNode in="shadowMatrixOuter1"></feMergeNode>
          <feMergeNode in="SourceGraphic"></feMergeNode>
        </feMerge>
      </filter>
    </defs>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g>
        <g filter={filter} transform="translate(23.000000, 23.000000) scale(-1, 1)
        translate(-23.000000, -23.000000) translate(3.000000, 3.000000)">
          <path d="M35.6756757,2.10526316 L35.6756757,2.10807018 C36.8922523,2.10807018
          37.8378378,3.02877193 37.8378378,4.21333333 L37.8378378,25.2659649 C37.8378378,26.4498246
          36.8922523,27.3712281 35.6756757,27.3712281 L30.8108108,27.3712281 C30.1715315,27.3684211
          29.6706306,27.9024561 29.7297297,28.5221053 L30.5405405,36.1045614 L21.8414414,27.6645614
          C21.6381982,27.4722807 21.3657658,27.365614 21.0810811,27.3684211 L4.32432432,27.3684211
          C3.10774775,27.3684211 2.16216216,26.4470175 2.16216216,25.2631579 L2.16216216,4.21052632
          C2.16216216,3.02596491 3.10774775,2.10526316 4.32432432,2.10526316 L35.6756757,2.10526316
          Z M31.8918919,6.84210526 C32.4886486,6.84210526 32.972973,7.31368421 32.972973,7.89473684
          C32.972973,8.47578947 32.4886486,8.94736842 31.8918919,8.94736842 L8.10810811,8.94736842
          C7.51135135,8.94736842 7.02702703,8.47578947 7.02702703,7.89473684 C7.02702703,7.31368421
          7.51135135,6.84210526 8.10810811,6.84210526 L31.8918919,6.84210526 Z M31.8918919,13.6842105
          C32.4886486,13.6842105 32.972973,14.1557895 32.972973,14.7368421 C32.972973,15.3178947
          32.4886486,15.7894737 31.8918919,15.7894737 L8.10810811,15.7894737 C7.51135135,15.7894737
          7.02702703,15.3178947 7.02702703,14.7368421 C7.02702703,14.1557895 7.51135135,13.6842105
          8.10810811,13.6842105 L31.8918919,13.6842105 Z M31.8918919,20.5263158 C32.4886486,20.5263158
          32.972973,20.9978947 32.972973,21.5789474 C32.972973,22.16 32.4886486,22.6315789 31.8918919,22.6315789
          L8.10810811,22.6315789 C7.51135135,22.6315789 7.02702703,22.16 7.02702703,21.5789474 C7.02702703,20.9978947
          7.51135135,20.5263158 8.10810811,20.5263158 L31.8918919,20.5263158 Z"
          id="Page-1-Copy-12" fill={color} ></path>
          <path d="M35.6756757,0.0184989194 C38.0518919,0.0184989194 40,1.91534102 40,4.22902524 L40,25.2816568
          C40,27.595341 38.0518919,29.4921831 35.6756757,29.4921831 L32.0100901,29.4921831 L32.9895495,38.8507796
          C33.0796396,39.8184989 31.8861261,40.3770954 31.1654054,39.7055165 L20.6421622,29.4921831
          L4.32432432,29.4921831 C1.94810811,29.4921831 0,27.595341 0,25.2816568 L0,4.22902524 C0,1.91534102
          1.94810811,0.0184989194 4.32432432,0.0184989194 L35.6756757,0.0184989194 Z M35.6756757,2.12376208
          L4.32432432,2.12376208 C3.10774775,2.12376208 2.16216216,3.04446383 2.16216216,4.22902524
          L2.16216216,25.2816568 C2.16216216,26.4655165 3.10774775,27.38692 4.32432432,27.38692
          L21.0810811,27.38692 C21.3657658,27.384113 21.6381982,27.4907796 21.8414414,27.6830603 L30.5405405,36.1230603
          L29.7297297,28.5406042 C29.6706306,27.9209551 30.1715315,27.38692 30.8108108,27.389727 L35.6756757,27.389727
          C36.8922523,27.389727 37.8378378,26.4683235 37.8378378,25.2844638 L37.8378378,4.23183225
          C37.8378378,3.04727085 36.8922523,2.12656909 35.6756757,2.12656909 L35.6756757,2.12376208
          Z M31.8918919,6.86060418 C32.4886486,6.86060418 32.972973,7.33218313 32.972973,7.91323576
          C32.972973,8.49428839 32.4886486,8.96586734 31.8918919,8.96586734 L8.10810811,8.96586734
          C7.51135135,8.96586734 7.02702703,8.49428839 7.02702703,7.91323576 C7.02702703,7.33218313
          7.51135135,6.86060418 8.10810811,6.86060418 L31.8918919,6.86060418 Z M31.8918919,13.7027094
          C32.4886486,13.7027094 32.972973,14.1742884 32.972973,14.755341 C32.972973,15.3363937 32.4886486,15.8079726
          31.8918919,15.8079726 L8.10810811,15.8079726 C7.51135135,15.8079726 7.02702703,15.3363937 7.02702703,14.755341
          C7.02702703,14.1742884 7.51135135,13.7027094 8.10810811,13.7027094 L31.8918919,13.7027094
          Z M31.8918919,20.5448147 C32.4886486,20.5448147 32.972973,21.0163937 32.972973,21.5974463
          C32.972973,22.1784989 32.4886486,22.6500779 31.8918919,22.6500779 L8.10810811,22.6500779
          C7.51135135,22.6500779 7.02702703,22.1784989 7.02702703,21.5974463 C7.02702703,21.0163937
          7.51135135,20.5448147 8.10810811,20.5448147 L31.8918919,20.5448147 Z" id="Page-1" fill="#5B616B"></path>
        </g>
      </g>
    </g>
  </svg>;
};
ReaderCommentIcon.propTypes = {

  /**
  Sets the selected color of the component. Default value is 'COLORS.GOLD_LIGHT'.
  */
  color: PropTypes.string,

  /**
  Sets the selected prop of the component. Default value is 'false'.
  */
  selected: PropTypes.bool,

  /**
  Sets the id of the component. Default value is '1'.
  */
  id: PropTypes.number,

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.LARGE'.
  */
  size: PropTypes.number,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string,
};
ReaderCommentIcon.defaultProps = {
  color: COLORS.GOLD_LIGHT,
  selected: false,
  id: 1,
  size: ICON_SIZES.LARGE,
  classNameName: ''
};
