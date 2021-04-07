import React from 'react';

import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { render, fireEvent, screen } from '@testing-library/react';
import { setTimeSlots, formatTimeSlotLabel, hearingTimeOptsWithZone } from 'app/hearings/utils';
import { axe } from 'jest-axe';

import REGIONAL_OFFICE_INFORMATION from '../../../../../constants/REGIONAL_OFFICE_INFORMATION';
import HEARING_TIME_OPTIONS from '../../../../../constants/HEARING_TIME_OPTIONS';

import moment from 'moment-timezone/moment-timezone';

const emptyHearings = [];
const oneHearing = [{
  hearingTime: '10:15',
  externalId: '249a1443-0de4-44fd-bd93-58c30f14c703'
}];
const defaultRoCode = 'RO39';
const defaultProps = {
  // Denver
  ro: defaultRoCode,
  roTimezone: REGIONAL_OFFICE_INFORMATION[defaultRoCode].timezone,
  hearings: emptyHearings,
  fetchScheduledHearings: jest.fn(),
  onChange: jest.fn()
};

const setup = (props = {}) => {
  const mergedProps = { ...defaultProps, ...props };

  console.log(mergedProps.hearings);
  const utils = render(<TimeSlot {...mergedProps} />);
  const container = utils.container;
  const timeSlots = setTimeSlots(
    props.hearings || defaultProps.hearings,
    props.ro || defaultProps.ro,
    props.roTimezone || defaultProps.roTimezone,
  );
  const dropdownItems = hearingTimeOptsWithZone(
    HEARING_TIME_OPTIONS,
    props.roTimezone || defaultProps.roTimezone,
    props.roTimezone || defaultProps.roTimezone,
  );

  return { container, utils, timeSlots, dropdownItems };
};

const toggleToCustomLink = (utils) => utils.queryByText('Choose a custom time');
const toggleToSlotsLink = (utils) => utils.queryByText('Choose a time slot');

const toggleTo = ({ toSlots, utils }) => {
  const toggleLink = toSlots ? toggleToSlotsLink(utils) : toggleToCustomLink(utils);

  if (toggleLink) {
    fireEvent.click(toggleLink);
  }
};

const toggleToSlots = (utils) => toggleTo({ toSlots: true, utils });
const toggleToCustom = (utils) => toggleTo({ toSlots: false, utils });
const toggleBackAndForth = (utils) => {
  if (toggleToCustomLink(utils)) {
    toggleToCustom(utils);
    toggleToSlots(utils);
  }
  if (toggleToSlots(utils)) {
    toggleToSlots(utils);
    toggleToCustom(utils);
  }
};

const firstAndLastSlotsAreCorrect = (ro, timeSlots) => {
  if (ro.label === 'Central') {
    const nineAmRoZone = moment.tz('09:00', 'HH:mm', ro.timezone);
    const fourPmEastern = moment.tz('16:00', 'HH:mm', 'America/New_York');

    // First slot is at 8:30am roTime
    expect(timeSlots[0].time.isSame(nineAmRoZone, 'hour')).toEqual(true);
    // Last slot is at 3:30pm eastern
    expect(timeSlots[timeSlots.length - 1].time.isSame(fourPmEastern, 'hour')).toEqual(true);
  }
  if (ro.label !== 'Central') {
    const eightThirtyAmRoZone = moment.tz('8:30', 'HH:mm', ro.timezone);
    const threeThirtyPmEastern = moment.tz('15:30', 'HH:mm', 'America/New_York');

    // First slot is at 8:30am roTime
    expect(timeSlots[0].time.isSame(eightThirtyAmRoZone, 'hour')).toEqual(true);
    // Last slot is at 3:30pm eastern
    expect(timeSlots[timeSlots.length - 1].time.isSame(threeThirtyPmEastern, 'hour')).toEqual(true);
  }
};
const firstDropdownItemCorrect = (ro, item) => {
  const eightFifteenRoTimeMoment = moment.tz('08:15', 'HH:mm', ro.timezone);
  const easternTimeString = eightFifteenRoTimeMoment.tz('America/New_York').format('h:mm');
  const roTimeString = eightFifteenRoTimeMoment.tz(ro.timezone).format('h:mm');

  expect(item.label).toContain(easternTimeString);
  expect(item.label).toContain(roTimeString);
};
const lastDropdownItemCorrect = (ro, item) => {
  const fourFortyFiveRoTimeMoment = moment.tz('16:45', 'HH:mm', ro.timezone);
  const easternTimeString = fourFortyFiveRoTimeMoment.tz('America/New_York').format('h:mm');
  const roTimeString = fourFortyFiveRoTimeMoment.tz(ro.timezone).format('h:mm');

  expect(item.label).toContain(easternTimeString);
  expect(item.label).toContain(roTimeString);
};

const firstLastAndCountOfDropdownItemsCorrect = (ro, dropdownItems) => {
  firstDropdownItemCorrect(ro, dropdownItems[0]);
  lastDropdownItemCorrect(ro, dropdownItems[dropdownItems.length - 1]);
  expect(dropdownItems.length).toEqual(35);
};

describe('TimeSlot', () => {
  describe('has correct visual elements', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = setup();
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('should have 1 button for each time slot and 1 button to change to custom time', () => {
      const { utils, timeSlots } = setup();

      expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
      expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);
    });

    it('changes between custom and pre-defined times when button link clicked', () => {
      const { utils, timeSlots } = setup();

      // Click the toggle
      fireEvent.click(screen.getByText('Choose a custom time'));

      // Check that the correct elements are displayed
      expect(utils.getAllByRole('button')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-container')).toHaveLength(0);

      // Click the toggle
      fireEvent.click(screen.getByText('Choose a time slot'));

      // Check that the correct types of elements are displayed
      expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
      expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);
    });

    it('selects a time slot when clicked', () => {
      const { utils, timeSlots } = setup();

      // Click 2 different hearing times
      fireEvent.click(screen.getByText(formatTimeSlotLabel('10:30', defaultProps.roTimezone)));
      fireEvent.click(screen.getByText(formatTimeSlotLabel('11:30', defaultProps.roTimezone)));

      // Check that the correct elements are displayed
      expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
      expect(document.getElementsByClassName('time-slot-button-selected')).toHaveLength(1);
    });
  });

  describe('has correct behavior in multiple timezones', () => {
    const regionalOfficeCodes = [
      // New York, Eastern time
      'RO06',
      // DC, Eastern time, central RO is special
      'C',
      // St. Paul, Central time
      'RO76',
      // Denver, Mountain time
      'RO39',
      // Oakland, Pacific time
      'RO43',
    ];
    const regionalOffices = regionalOfficeCodes.map((roCode) => {
      return { ro: roCode, timezone: REGIONAL_OFFICE_INFORMATION[roCode].timezone
      };
    });

    regionalOffices.forEach((ro) => {
      it('has correct slot times', () => {
        const { timeSlots, utils } = setup({ roTimezone: ro.timezone });

        // Sanity check, but also remove linting problems because expects are in sub-functions
        expect(timeSlots.length > 0).toEqual(true);
        firstAndLastSlotsAreCorrect(ro, timeSlots);

        // Toggle back and forth, check that they're still correct
        toggleBackAndForth(utils);
        firstAndLastSlotsAreCorrect(ro, timeSlots);
      });

      it('has correct custom dropdown options', () => {
        const { dropdownItems, utils } = setup({ roTimezone: ro.timezone });

        toggleToCustom(utils);
        // Check that the dropdown times are correct
        expect(dropdownItems.length > 0).toEqual(true);
        firstLastAndCountOfDropdownItemsCorrect(ro, dropdownItems);
        // Toggle back and forth, check that they're still correct
        toggleBackAndForth(utils);
        firstLastAndCountOfDropdownItemsCorrect(ro, dropdownItems);
      });

      it('has correct time values to submit to backend', () => {
        const { timeSlots, dropdownItems } = setup({ roTimezone: ro.timezone });

        // Check that the value for the slot matches what we send when we schedule
        timeSlots.forEach((slot) => {
          expect(slot.time.tz('America/New_York').format('HH:mm')).toEqual(slot.hearingTime);
        });

        // Check that the value for the dropdown matches what we send when we schedule
        dropdownItems.forEach((item) => {
          const time = moment.tz(item.value, 'HH:mm', 'America/New_York').format('h:mm A');
          const expectedLabelPart = `${time} Eastern`;

          expect(item.label).toContain(expectedLabelPart);
        });
      });
      it('hearings have correct times', () => {
        const { utils, timeSlots } = setup({ hearings: oneHearing, roTimezone: ro.timezone });

        // The timeSlots list actually contains a mix of hearings and slots, pull out the one hearing
        const hearingInSlotList = timeSlots.filter((item) => item.full === true);

        expect(hearingInSlotList.length).toEqual(1);
        const time = moment.tz(hearingInSlotList[0].hearingTime, 'HH:mm', 'America/New_York').format('h:mm A');
        const expectedLabelPart = `${time} Eastern`;
        // const buttons = utils.getByText(expectedLabelPart);

        // expect(buttons.length).toEqual(1);

        // expect(hearing.label).toContain(expectedLabelPart);

      });
      it('hides slots based on scheduled hearings', () => {});
      it('hides slots based on the beginning and end of the work day', () => {});
    });
  });
})
;
