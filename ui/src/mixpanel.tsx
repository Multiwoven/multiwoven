import mixpanel, { Dict } from 'mixpanel-browser';
mixpanel.init('e63798d0375591916b52f5d8e7d445f8');

const actions = {
  identify: (id: string) => {
    mixpanel.identify(id);
  },
  alias: (id: string) => {
    mixpanel.alias(id);
  },
  track: (name: string, props: Dict) => {
    mixpanel.track(name, props);
  },
  people: {
    set: (props: Dict) => {
      mixpanel.people.set(props);
    },
  },
};

export const Mixpanel = actions;
