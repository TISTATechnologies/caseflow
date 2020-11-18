import { createSlice, createAction, createAsyncThunk } from '@reduxjs/toolkit';
import { differenceWith, differenceBy, find, pick, random, range } from 'lodash';
import uuid from 'uuid';
import * as PDF from 'pdfjs';

// Local Dependencies
import ApiUtil from 'app/util/ApiUtil';
import { ENDPOINT_NAMES, ROTATION_INCREMENTS, COMPLETE_ROTATION, COMMENT_ACCORDION_KEY } from 'store/constants/reader';
import { addMetaLabel, formatCategoryName } from 'utils/reader';

/**
 * PDF SideBar Error State
 */
const initialPdfSidebarErrorState = {
  tag: { visible: false, message: null },
  category: { visible: false, message: null },
  annotation: { visible: false, message: null },
  description: { visible: false, message: null }
};

/**
 * PDF Initial State
 */
export const initialState = {
  hideSearchBar: true,
  hidePdfSidebar: false,
  scrollToComment: null,
  pageDimensions: {},
  documentErrors: {},
  text: [],
  selected: {},
  loading: false,
  openedAccordionSections: ['Categories', 'Issue tags', COMMENT_ACCORDION_KEY],
  tagOptions: {},
  jumpToPageNumber: null,
  scrollTop: 0,
  pdfSideBarError: initialPdfSidebarErrorState,
  scrollToSidebarComment: null,
  scale: 1,
  windowingOverscan: random(5, 10),
  search: {
    matchIndex: 0,
    indexToHighlight: null,
    relativeIndex: 0,
    pageIndexWithMatch: null,
    extractedText: {},
    searchIsLoading: false
  }
};

/**
 * Method for Extracting text from PDF Documents
 */
export const getDocumentText = createAsyncThunk('pdfSearch/documentText', async ({ pdfDocument, file }) => {
  // Create a function to extract text
  const extractText = (index) => pdfDocument.getPage(index + 1).then((page) => page.getTextContent());

  // Map the Extract to promises
  const textPromises = range(pdfDocument.pdfInfo.numPages).map((index) => extractText(index));

  // Wait for the search to complete
  const pages = await Promise.all(textPromises);

  // Reduce the Pages to an object containing the matches
  return pages.
    reduce((acc, page, pageIndex) => ({
      ...acc,
      [`${file}-${pageIndex}`]: {
        id: `${file}-${pageIndex}`,
        file,
        text: page.items.map((row) => row.str).join(' '),
        pageIndex
      }
    }),
    {});
});

export const showPage = createAsyncThunk('documentViewer/changePage', async(params) => {
  // Convert the Array Buffer to a PDF
  const pdf = await PDF.getDocument({ data: params.data }).promise;

  console.log('PDF INFO: ', pdf.numPages);

  // Get the first page
  const page = await pdf.getPage(1);

  console.log('PAGE: ', page);

  // Select the canvas element to draw
  const canvas = document.getElementById('pdf-canvas');

  // Draw the PDF to the canvas
  await page.render({
    canvasContext: canvas.getContext('2d', { alpha: false }),
    viewport: page.getViewport(params.scale)
  }).promise;

  // Update the store with the PDF Pages
  return {
    docId: params.docId,
    numPages: pdf.numPages
  };
});

/**
 * Dispatcher to show the selected PDF
 */
export const showPdf = createAsyncThunk('documentViewer/show', async ({
  currentDocument,
  worker,
  scale
}, { dispatch }) => {
  // Attach the Service Worker if not already attached
  if (PDF.GlobalWorkerOptions.workerSrc !== worker) {
    PDF.GlobalWorkerOptions.workerSrc = worker;
  }

  // Get the Selected Document
  // const [currentDocument] = documents.filter((doc) => doc.id.toString() === docId);

  // Request the Document if it is not loaded
  // if (current.id !== currentDocument.id) {
  // Request the PDF document from eFolder
  const { body } = await ApiUtil.get(currentDocument.content_url, {
    cache: true,
    withCredentials: true,
    timeout: true,
    responseType: 'arraybuffer'
  });

  // Set the Page
  dispatch(showPage({ scale, data: body, docId: currentDocument.id }));
  // }

  // Return the Document Buffer
  return { selected: currentDocument };
});

/**
 * Dispatcher to Remove Tags from a Document
 */
export const removeTag = createAsyncThunk('documentViewer/removeTag', async({ doc, tag }) => {
  // Request the deletion of the selected tag
  await ApiUtil.delete(`/document/${doc.id}/tag/${tag.id}`, {}, ENDPOINT_NAMES.TAG);

  // Return the selected document and tag to the next Dispatcher
  return { doc, tag };
});

/**
 * Dispatcher to Add Tags for a Document
 */
export const addTag = createAsyncThunk('documentViewer/addTag', async({ doc, newTags }) => {
  // Request the addition of the selected tags
  const { body } = await ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }, ENDPOINT_NAMES.TAG);

  // Return the selected document and tag to the next Dispatcher
  return { doc, newTags, ...body };
});

/**
 * Dispatcher to Save Description for a Document
 */
export const saveDocumentDescription = createAsyncThunk('documentViewer/saveDescription', async({ docId, description }) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(`/document/${docId}`, { data: { description } });

  // Return the selected document and tag to the next Dispatcher
  return { docId, description };
});

/**
 * Dispatcher to Remove Tags from a Document
 */
export const selectCurrentPdf = createAsyncThunk('documentViewer/saveDescription', async({ docId }) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(`/document/${docId}/mark-as-read`, {}, ENDPOINT_NAMES.MARK_DOC_AS_READ);

  // Return the selected document and tag to the next Dispatcher
  return { docId };
});

/**
 * Dispatcher to Set the PDF as Opened
 */
export const selectCurrentPdfLocally = createAction('documentViewer/selectCurrentPdfLocally');

/**
 * Dispatcher to Set the PDF as Opened
 */
export const toggleDocumentCategoryFail = createAction('documentViewer/toggleDocumentCategoryFail');

/**
 * Dispatcher to Remove Tags from a Document
 */
export const handleCategoryToggle = createAsyncThunk('documentViewer/handleCategoryToggle', async({
  docId,
  categoryKey,
  toggleState
}) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(
    `/document/${docId}`,
    { data: { [categoryKey]: toggleState } },
    ENDPOINT_NAMES.DOCUMENT
  );

  // Return the selected document and tag to the next Dispatcher
  return { docId };
});

/**
 * PDF Combined Reducer/Action creators
 */
const documentViewerSlice = createSlice({
  name: 'documentViewer',
  initialState,
  reducers: {
    updateSearchIndex: {
      reducer: (state, action) => {
        // Increment or Decrement the match index based on the payload
        state.matchIndex = action.payload.increment ?
          state.matchIndex + 1 :
          state.matchIndex - 1;
      },
      prepare: (increment) => ({ payload: { increment } })
    },
    setSearchIndex: {
      reducer: (state, action) => {
        // Update the Search Index
        state.matchIndex = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    setSearchIndexToHighlight: {
      reducer: (state, action) => {
        // Update the Search Index
        state.matchIndex = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    updateSearchIndexPage: {
      reducer: (state, action) => {
        // Update the Page Index
        state.pageIndexWithMatch = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    updateSearchRelativeIndex: {
      reducer: (state, action) => {
        // Update the Relative Index
        state.relativeIndex = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    searchText: {
      reducer: (state, action) => {
        // Update the Search Term
        state.searchTerm = action.payload.searchTerm;

        // Set the search index to 0
        state.matchIndex = 0;
      },
      prepare: (searchTerm) => ({ payload: { searchTerm } })
    },
    setSearchIsLoading: {
      reducer: (state, action) => {
        // Update the Search Term
        state.searchIsLoading = action.payload.searchIsLoading;
      },
      prepare: (searchIsLoading) => ({ payload: { searchIsLoading } })
    },
    handleSelectCommentIcon: {
      reducer: (state, action) => {
        state.scrollToSidebarComment = action.payload.scrollToSidebarComment;
      },
      prepare: (comment) => ({ payload: { scrollToSidebarComment: comment } })
    },
    changePendingDocDescription: {
      reducer: (state, action) => {
        state.list[action.payload.docId].pendingDescription = action.payload.description;
      },
      prepare: (docId, description) => ({ payload: { docId, description } })
    },
    resetPendingDocDescription: {
      reducer: (state, action) => {
        delete state.list[action.payload.docId].pendingDescription;
      },
      prepare: (docId, description) => ({ payload: { docId, description } })
    },
    rotateDocument: {
      reducer: (state, action) => {
        // Calculate the rotation Based on the Rotation Increments
        const rotation =
         (state.list[action.payload.docId].rotation + ROTATION_INCREMENTS) % COMPLETE_ROTATION;

        // Update the rotation of the document
        state.list[action.payload.docId].rotation = rotation;
      },
      prepare: (docId) => ({ payload: { docId } })
    },
    closeDocumentUpdatedModal: {
      reducer: (state, action) => {
        // Update the rotation of the document
        state.list[action.payload.docId].wasUpdated = false;
      },
      prepare: (docId) => ({ payload: { docId } })
    },
    handleToggleCommentOpened: {
      reducer: (state, action) => {
        // Update the rotation of the document
        state.list[action.payload.docId].listComments =
          !state.list[action.payload.docId].listComments;
      },
      prepare: (docId) =>
        addMetaLabel('toggle-comment-list', { docId }, (state) =>
          state.list[docId].listComments ? 'open' : 'close')
    },
  },
  extraReducers: (builder) => {
    builder.
      addCase(showPdf.pending, (state) => {
        state.loading = true;
      }).
      addCase(showPage.fulfilled, (state, action) => {
      // Add the PDF data to the store
        state.selected = action.payload;
      }).
      /* eslint-disable */
      addCase(selectCurrentPdf.rejected, (state, action) => {
        console.log('Error marking as read', action.payload.docId, action.payload.errorMessage);
      }).
      /* eslint-enable */
      addCase(saveDocumentDescription.fulfilled, (state, action) => {
        state.list[action.payload.doc.id].description = action.payload.description;
      }).
      addCase(addTag.pending, {
        reducer: (state, action) => {
        // Set the tags that are being created
          state.list[action.payload.doc.id].tags.push(action.payload.newTags);
        },
        prepare: (doc, tags) => {
        // Calculate the new Tags
          const newTags = differenceWith(doc.tags, tags, (tag, currentTag) =>
            tag.value === currentTag.text).map((tag) => ({ text: tag.label, id: uuid.v4(), temporaryId: true }));

          // Return the formatted payload
          return {
            payload: {
              newTags,
              doc
            }
          };
        }
      }).
      addCase(addTag.fulfilled, (state, action) => {
        state.list[action.payload.doc.id].tags = state.list[action.payload.doc.id].tags.map((tag) => {
          // Locate the created tag
          const createdTag = find(action.payload.tags, pick(tag, 'text'));

          // If there is a created Tag, return that
          if (createdTag) {
            return createdTag;
          }

          // Default to return the original tag
          return tag;
        });
      }).
      addCase(addTag.rejected, (state, action) => {
      // Remove the tags that were attempted to be added
        state.list[action.payload.doc.id].tags =
        differenceBy(state.list[action.payload.doc.id].tags, action.payload.newTags, 'text');
      }).
      addCase(removeTag.pending, (state, action) => {
      // Set the pending Removal for the selected tag to true
        state.list[action.payload.doc.id].tags[action.payload.tag.id].pendingRemoval = true;
      }).
      addCase(removeTag.fulfilled, (state, action) => {
      // Remove the tag from the list
        delete state.list[action.payload.doc.id].tags[action.payload.tag.id];
      }).
      addCase(removeTag.rejected, (state, action) => {
        // Reset the pending Removal for the selected tag to false
        state.list[action.payload.doc.id].tags[action.payload.tag.id].pendingRemoval = false;
      }).

      addCase(handleCategoryToggle.fulfilled, {
        reducer: (state, action) => {
          state.list[action.payload.docId][action.payload.categoryKey] = action.payload.toggleState;
        },
        prepare: (payload) =>
          addMetaLabel(`${payload.toggleState ? 'set' : 'unset'} document category`, payload, payload.categoryName)
      }).
      addCase(handleCategoryToggle.pending, {
        prepare: (docId, categoryName, toggleState) => {
          const categoryKey = formatCategoryName(categoryName);

          return {
            payload: {
              docId,
              categoryKey,
              toggleState
            }
          };
        }
      }).
      addMatcher(
        (action) => [
          toggleDocumentCategoryFail.toString(),
          handleCategoryToggle.rejected.toString()
        ].includes(action.type),
        (state, action) => {
          state.list[action.payload.docId][action.payload.categoryKey] = !action.payload.toggleState;
        }
      ).
      addMatcher(
        (action) => [
          selectCurrentPdf.fulfilled.toString(),
          selectCurrentPdfLocally.toString()
        ].includes(action.type),
        (state, action) => {
          state.list[action.payload.docId].opened_by_current_user = true;
        }
      );
  }
});

// Export the Reducer actions
export const {
  changePendingDocDescription,
  resetPendingDocDescription,
  rotateDocument,
  closeDocumentUpdatedModal,
  handleToggleCommentOpened,
  handleSelectCommentIcon,
  onScrollToComment,
  setZoomLevel
} = documentViewerSlice.actions;

// Default export the reducer
export default documentViewerSlice.reducer;

