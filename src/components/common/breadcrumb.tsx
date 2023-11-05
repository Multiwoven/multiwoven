import React from 'react';
import { useLocation } from 'react-router-dom';
import { HomeIcon, ChevronRightIcon } from '@heroicons/react/24/outline';

interface BreadcrumbProps {
  customName?: string,
  id?: string;
}

export const Breadcrumb: React.FC<BreadcrumbProps> = ({ customName, id }) => {
  const location = useLocation();
  const pathSegments = location.pathname.split('/').filter((segment) => segment !== '');

  const breadcrumbSegments: string[] = [];

  pathSegments.forEach((segment, index) => {
    if (segment === 'show') {
      breadcrumbSegments.push(customName || 'Custom Name for Show Route');
    } else if (segment !== 'show' && segment !== id) {
      breadcrumbSegments.push(segment);
    }
  });

  console.log(breadcrumbSegments)

  return (
    <nav className="flex" aria-label="Breadcrumb">
      <ol className="flex items-center space-x-4">
        <li>
          <div>
            <a href="/" className="text-gray-400 hover-text-gray-500">
              <HomeIcon className="h-5 w-5 flex-shrink-0" aria-hidden="true" />
              <span className="sr-only">Home</span>
            </a>
          </div>
        </li>
        {breadcrumbSegments.map((segment, index) => (
          <li key={segment}>
            <div className="flex items-center">
              {index < breadcrumbSegments.length && (
                <ChevronRightIcon className="h-5 w-5 flex-shrink-0 text-gray-400" aria-hidden="true" />
              )}
              <a
                href={`/${breadcrumbSegments.slice(0, index + 1).join('/')}`}
                className="ml-4 text-sm font-medium text-gray-500 hover-text-gray-700"
                aria-current={index === breadcrumbSegments.length - 1 ? 'page' : undefined}
              >
                {titleCase(segment)}
              </a>
            </div>
          </li>
        ))}
      </ol>
    </nav>
  );
};

// Helper function to convert a string to Title case
function titleCase(str: string) {
  return str
    .toLowerCase()
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}
