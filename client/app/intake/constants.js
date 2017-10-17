export const PAGE_PATHS = {
  BEGIN: '/',
  REVIEW: '/review-request',
  FINISH: '/finish',
  COMPLETED: '/completed'
};

export const ACTIONS = {
  START_NEW_INTAKE: 'START_NEW_INTAKE',
  SET_FILE_NUMBER_SEARCH: 'SET_FILE_NUMBER_SEARCH',
  FILE_NUMBER_SEARCH_START: 'FILE_NUMBER_SEARCH_START',
  FILE_NUMBER_SEARCH_SUCCEED: 'FILE_NUMBER_SEARCH_SUCCEED',
  FILE_NUMBER_SEARCH_FAIL: 'FILE_NUMBER_SEARCH_FAIL',
  SET_OPTION_SELECTED: 'SET_OPTION_SELECTED',
  SET_RECEIPT_DATE: 'SET_RECEIPT_DATE',
  TOGGLE_CANCEL_MODAL: 'TOGGLE_CANCEL_MODAL',
  SUBMIT_REVIEW_START: 'SUBMIT_REVIEW_START',
  SUBMIT_REVIEW_SUCCEED: 'SUBMIT_REVIEW_SUCCEED',
  SUBMIT_REVIEW_FAIL: 'SUBMIT_REVIEW_FAIL'
};

export const REQUEST_STATE = {
  NOT_STARTED: 'NOT_STARTED',
  IN_PROGRESS: 'IN_PROGRESS',
  SUCCEEDED: 'SUCCEEDED',
  FAILED: 'FAILED'
};

export const RAMP_INTAKE_STATES = {
  NONE: 'NONE',
  STARTED: 'STARTED',
  REVIEWED: 'REVIEWED',
  COMPLETED: 'COMPLETED'
};
