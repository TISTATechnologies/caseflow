import React from 'react';
import NavigationBar from './NavigationBar';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import { LOGO_COLORS } from '../constants/AppConstants';
import { StaticRouter, Route } from 'react-router-dom';
import ReduxBase from '../components/ReduxBase';
import queueReducer, { initialState } from '../queue/reducers';

const storyState = {
  appName: '',
  key: '/queue',
  extraBanner: <PerformanceDegradationBanner showBanner={false} />,
  userDisplayName: '',
  dropdownUrls: [{
    title: 'Queue',
    link: '/queue',
    target: '#top',
    border: false
  }],
  topMessage: null,
  defaultUrl: '/path/to/desired/route'

};

const RouterDecorator = (storyFn) => (
  <StaticRouter
    location={{
      pathname: '/',
    }}
  >
    <Route
      path="/"
    >
      {storyFn()}
    </Route>
  </StaticRouter>
);

const ReduxDecorator = (storyFn) => (
  <ReduxBase
    reducer={queueReducer}
    initialState={{ queue: { ...initialState, ...storyState } }}
  >
    {storyFn()}
  </ReduxBase>
);

export default {
  title: 'Commons/Components/Layout/NavigationBar',
  component: NavigationBar,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    appName: 'Navigation Bar Demo',
    userDisplayName: 'Rick Sanchez',
    logoProps: {
      accentColor: LOGO_COLORS.QUEUE.ACCENT,
      overlapColor: LOGO_COLORS.QUEUE.OVERLAP
    }
  },
  argTypes: {
    appName: { description: 'Name of application.', control: 'text' },
    userDisplayName: { description: 'Display name of the current User.', control: 'text' },
    logoProps: { description: 'Props passed down to the `CaseflowLogo` component.' }
  },
  decorators: [RouterDecorator, ReduxDecorator],
};
const Template = (args) => <NavigationBar {...args} />;

export const Basic = Template.bind({});
