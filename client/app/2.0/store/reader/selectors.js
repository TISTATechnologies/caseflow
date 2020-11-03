// External Dependencies
import { createSelector, current } from '@reduxjs/toolkit';
import { values, isEmpty, compact, uniqBy } from 'lodash';

// Local Dependencies
import { escapeRegExp, loadAppeal, documentsView } from 'utils/reader';

/**
 * Selector for the Filtered Doc IDs
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Filtered Doc IDs
 */
export const filteredDocIdState = (state) => state.reader.documentList.filteredDocIds;

/**
 * Selector for the Documents
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents
 */
export const documentState = (state) => state.reader.documents.list;

/**
 * Selector for the Editing Annotation State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Editing Annotation State
 */
export const pendingEditingAnnotationState = (state) => state.reader.annotationLayer.pendingEditingAnnotations;

/**
 * Selector for the Editing Annotation State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Editing Annotation State
 */
export const annotationState = (state) => state.reader.annotationLayer.annotations;

/**
 * Selector for the Editing Annotation State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Editing Annotation State
 */
export const pendingAnnotationState = (state) => state.reader.annotationLayer.pendingAnnotations;

/**
 * Selector that returns the text Pages are currently filtered by
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- Returns an Array of Page ids that match the current search :text
 */
export const searchTermState = (state) => state.reader.searchAction.searchTerm;

/**
 * Selector for the Extracted Text State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Extracted Text State
 */
export const extractedTextState = (state) => state.reader.searchAction.extractedText;

/**
 * Selector for the File State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The File State
 */
export const fileState = (state, props) => props.file;

/**
 * Selector for the Document Filter Criteria
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The File State
 */
export const filterCriteriaState = (state) => state.documentList.filterCriteria;

/**
 * Selector for the Selected Index
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The File State
 */
export const selectedIndexState = (state) => state.searchAction.matchIndex;

/**
 * Filtered Documents state
 */
export const filteredDocuments = ({ reader }) =>
  reader.documentList.filteredDocIds.reduce((list, id) => ({ ...list, [id]: reader.documents.list[id] }), {});

/**
 * Document List Filtered State
 */
export const docListIsFiltered = createSelector(
  [documentState, filteredDocIdState, filterCriteriaState],
  (documents, filteredDocIds, filterCriteria) =>
    Boolean(
      documents.length !== filteredDocIds.length ||
      filterCriteria.searchQuery ||
      values(filterCriteria.category).some() ||
      values(filterCriteria.tag).some()
    )
);

/**
 * Text within a file State
 */
export const textForFile = createSelector(
  [extractedTextState, fileState],
  (extractedText, file) => extractedText.filter((pageText) => pageText.file === file)
);

/**
 * Matches Per Page State
 */
export const matchesPerPage = createSelector(
  [textForFile, searchTermState],
  (text, searchTerm) => text.
    map((page) => ({
      id: page.id,
      pageIndex: page.pageIndex,
      matches: (page.text.match(new RegExp(escapeRegExp(searchTerm), 'gi')) || []).length
    })).
    filter((page) => page.matches > 0)
);

/**
 * Total Count of Pages with Matching text State
 */
export const totalMatches = createSelector(
  [matchesPerPage],
  (matches) => matches.map((match) => match.matches).sum()
);

/**
 * Index of the Currently Selected File that matches the search text State
 */
export const currentMatchIndex = createSelector(
  [totalMatches, selectedIndexState],
  (totalMatchesInFile, selectedIndex) => (selectedIndex + totalMatchesInFile) % totalMatchesInFile
);

/**
 * State of the Annotations by Document
 * @param {Object} state -- The current Redux store state
 */
export const documentAnnotations = (state) => {
  // Set the annotations
  const annotations = state.reader.annotationLayer;

  // Map the annotation keys to pull out the different annotation types
  const list = Object.keys(annotations).map((type) => {
    // Only switch if there are annotations
    if (isEmpty(annotations[type])) {
      return null;
    }

    // Handle the type
    switch (annotations) {
    case 'annotations':
    case 'pendingAnnotations':
    case 'pendingEditingAnnotations':
      return annotations[type];
    case 'editingAnnotations':
      return {
        ...annotations[type],
        editing: true
      };
    default:
      return {};
    }
  });

  // Return the formatted document annotations
  return uniqBy(compact(list), 'id').filter((item) => !item.pendingDeletion);
};

/**
 * State for the Document List Screen
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents List State
 */
export const documentListScreen = (state) => {
  // Set the filtered documents
  const documents = filteredDocuments(state);

  // Calculate the number of documents
  const docsCount = state.reader.documentList.filteredDocIds ?
    state.reader.documentList.filteredDocIds.length :
    Object.values(documents).length;

  return {
    documents,
    docsCount,
    storeDocuments: state.reader.documents.list,
    documentList: state.reader.documentList,
    annotations: documentAnnotations(state),
    documentsView: documentsView(
      Object.values(documents),
      state.reader.documentList.filterCriteria,
      state.reader.documentList.viewingDocumentsOrComments
    ),
    caseSelectedAppeal: state.reader.caseSelect.selectedAppeal,
    loadedAppealId: state.reader.pdfViewer.loadedAppealId,
    tagOptions: state.reader.pdfViewer.tagOptions,
    filterCriteria: state.reader.documentList.filterCriteria,
    filteredDocIds: state.reader.documentList.filteredDocIds,
    searchCategoryHighlights: state.reader.documentList.searchCategoryHighlights,
    manifestVbmsFetchedAt: state.reader.documentList.manifestVbmsFetchedAt,
    manifestVvaFetchedAt: state.reader.documentList.manifestVvaFetchedAt,
    queueRedirectUrl: state.reader.documentList.queueRedirectUrl,
    queueTaskType: state.reader.documentList.queueTaskType,
    documentFilters: state.reader.documentList.pdfList.filters,
    isPlacingAnnotation: state.reader.annotationLayer.isPlacingAnnotation,
    appeal: loadAppeal(
      state.reader.caseSelect.assignments,
      state.reader.pdfViewer.loadedAppealId,
      state.reader.pdfViewer.loadedAppeal
    )
  };
};

/**
 * State for the Document Screen
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Document State
 */
export const documentScreen = (state) => ({
  documents: filteredDocuments(state.reader),
  documentFilters: state.reader.documentList.pdfList.filters,
  storeDocuments: state.reader.documents,
  isPlacingAnnotation: state.reader.annotationLayer.isPlacingAnnotation,
  appeal: state.reader.pdfViewer.loadedAppeal,
  annotations: state.reader.annotationLayer.annotations,
  pdf: state.reader.pdf,
  pdfViewer: state.reader.pdf,
  annotationLayer: state.reader.annotationLayer,
});