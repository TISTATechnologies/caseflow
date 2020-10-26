// External Dependencies
import { compact } from 'lodash';

// Local Dependencies
import { documentCategories } from 'store/constants/reader';
import { doDatesMatch } from 'app/util/DateUtil';
import { formatCategoryName } from 'utils/reader/format';
import { annotationStateByDocId } from 'store/reader/selectors';

/**
 * Helper Method that checks whether the Document type matches the search query
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} doc -- The document with key `type` to be matched
 */
export const typeContainsString = (searchQuery, doc) => (doc.type.toLowerCase().includes(searchQuery));

/**
 * Helper Method that checks if the search string is in one of the document comments
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} state -- The current document state
 * @param {Object} doc -- Contains the ID of the document to check comments
 * @returns {boolean} -- Returns whether the comment contains the search string
 */
export const commentContainsString = (searchQuery, state, doc) => annotationStateByDocId(state)(doc.id).
  reduce((acc, annotation) =>
    acc || annotation.comment.toLowerCase().includes(searchQuery),
  false);

/**
 * Helper Method that checks if a comment contains the given search word
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} state -- The current document state
 * @param {Object} doc -- The document to check comments
 * @returns {boolean} -- Returns whether the comment contains the search word
 */
export const commentContainsWords = (searchQuery, state, doc) =>
  compact(searchQuery.split(' ')).some((word) => commentContainsString(word, state, doc));

/**
 * Helper Method that checks if a category contains the given search string
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} doc -- The document to check comments
 * @returns {boolean} -- Returns whether the category contains the search string
 */
export const categoryContainsString = (searchQuery, doc) =>
  Object.keys(documentCategories).reduce((acc, category) =>
    acc || (category.includes(searchQuery) && doc[formatCategoryName(category)]), false);

/**
 * Helper Method that checks if a category contains the given search word
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} doc -- The document to check comments
 * @returns {boolean} -- Returns whether the category contains the search word
 */
export const categoryContainsWords = (searchQuery, doc) =>
  Object.keys(documentCategories).
    reduce((result, category) => ({
      ...result,
      [`${category}`]: compact(searchQuery.split(' ')).some((word) =>
        category.includes(word) && doc[formatCategoryName(category)])
    }),
    {});

/**
 * Helper Method that checks if a tag contains the given search string
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} doc -- The document to check comments
 * @returns {boolean} -- Returns whether the tag contains the search string
 */
export const tagContainsString = (searchQuery, doc) =>
  Object.keys(doc.tags || {}).
    reduce((acc, tag) =>
      acc || (doc.tags[tag].text.toLowerCase().includes(searchQuery)),
    false);

/**
 * Helper Method that checks if a description contains the given search string
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} doc -- The document to check comments
 * @returns {boolean} -- Returns whether the tag contains the search string
 */
export const descriptionContainsString = (searchQuery, doc) =>
  doc.description && doc.description.toLowerCase().includes(searchQuery);

/**
 * Helper Method that checks if a description contains the given search string
 * @param {string} searchQuery -- The query being used to search
 * @param {Object} state -- The Current Redux store state
 * @returns {boolean} -- Returns whether the tag contains the search string
 */
export const searchString = (searchQuery, state) => (doc) =>
  compact(searchQuery.split(' ')).every((word) => {
    const searchWord = word.trim();

    return searchWord.length > 0 && (
      doDatesMatch(doc.receivedAt, searchWord) ||
      commentContainsString(word, state, doc) ||
      typeContainsString(searchWord, doc) ||
      categoryContainsString(searchWord, doc) ||
      tagContainsString(searchWord, doc) ||
      descriptionContainsString(searchWord, doc));
  });
