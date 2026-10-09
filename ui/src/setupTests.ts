// Polyfill for TextEncoder/TextDecoder in Jest environment
import { TextEncoder as NodeTextEncoder, TextDecoder as NodeTextDecoder } from 'util';
import React from 'react';

if (typeof TextEncoder === 'undefined') {
  global.TextEncoder = NodeTextEncoder as typeof TextEncoder;
  global.TextDecoder = NodeTextDecoder as typeof TextDecoder;
}

// Ensure React is available globally for React.Fragment usage
if (typeof global.React === 'undefined') {
  global.React = React;
}
