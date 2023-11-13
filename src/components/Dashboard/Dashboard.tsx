import { Fragment, useState } from 'react'
import { Dialog, Menu, Transition } from '@headlessui/react'
import {
  BarsArrowDownIcon,
  ArrowPathIcon,
  ArrowsRightLeftIcon,
} from '@heroicons/react/24/outline'

import {
  BanknotesIcon,
  BuildingOfficeIcon,
  CheckCircleIcon,
  ChevronRightIcon,
} from '@heroicons/react/20/solid'
import { LineChart } from './chart'


const cards = [
  { name: 'Connections', href: '#', icon: ArrowsRightLeftIcon, amount: '5' },
  { name: 'Syncs', href: '#', icon: ArrowPathIcon, amount: '23' },
  { name: 'Rows Processed', href: '#', icon: BarsArrowDownIcon, amount: '2M' },
  // More items...
]
const transactions = [
  {
    id: 1,
    name: 'Payment to Molly Sanders',
    href: '#',
    amount: '$20,000',
    currency: 'USD',
    status: 'success',
    date: 'July 11, 2020',
    datetime: '2020-07-11',
  },
  // More transactions...
]

const statusStyles:any = {
  success: 'bg-green-100 text-green-800',
  processing: 'bg-yellow-100 text-yellow-800',
  failed: 'bg-gray-100 text-gray-800',
}


function classNames(...classes:any) {
  return classes.filter(Boolean).join(' ')
}

const activities = [
  {
    date: '2023-11-01 14:30:00',
    member: 'John Doe',
    action: 'Created Model',
    resourceName: 'Contacts',
    resourceType: 'Snowflake',
  },
  {
    date: '2023-10-29 09:45:00',
    member: 'John Doe',
    action: 'Updated Source',
    resourceName: 'Redshift',
    resourceType: 'Amazon Redshift',
  },
  {
    date: '2023-10-28 16:15:00',
    member: 'Bob Johnson',
    action: 'Deleted Destination',
    resourceName: 'Braze',
    resourceType: 'Braze',
  },
  {
    date: '2023-10-27 11:20:00',
    member: 'Eva Wilson',
    action: 'Created Model',
    resourceName: 'Locations',
    resourceType: 'Snowflake',
  },
  {
    date: '2023-10-25 14:00:00',
    member: 'John Doe',
    action: 'Created Source',
    resourceName: 'Contacts',
    resourceType: 'Snowflake',
  },
];



const Dashboard: React.FC = () => {
  return (
    <>
      <main className="flex-1 pb-8 bg-gray-100 border-b border-r border-l border-t">
           {/* Page header */}
            <div className="bg-white shadow">
              <div className="px-4 sm:px-6">
                <div className="py-6 md:flex md:items-center md:justify-between lg:border-t lg:border-gray-200">
                  <div className="min-w-0 flex-1">
                    {/* Profile */}
                    <div className="flex items-center">
                      <img
                        className="hidden h-16 w-16 rounded-full sm:block"
                        src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                        alt=""
                      />
                      <div>
                        <div className="flex items-center">
                          <img
                            className="h-16 w-16 rounded-full sm:hidden"
                            src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                            alt=""
                          />
                          <h1 className="ml-3 text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:leading-9">
                            Good morning, John Doe
                          </h1>
                        </div>
                        <dl className="mt-6 flex flex-col sm:ml-3 sm:mt-1 sm:flex-row sm:flex-wrap">
                          <dt className="sr-only">Company</dt>
                          <dd className="flex items-center text-sm font-medium capitalize text-gray-500 sm:mr-6">
                            <BuildingOfficeIcon
                              className="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                              aria-hidden="true"
                            />
                            Workspace
                          </dd>
                          <dt className="sr-only">Account status</dt>
                          <dd className="mt-3 flex items-center text-sm font-medium capitalize text-gray-500 sm:mr-6 sm:mt-0">
                            <CheckCircleIcon
                              className="mr-1.5 h-5 w-5 flex-shrink-0 text-green-400"
                              aria-hidden="true"
                            />
                            Workspace Admin
                          </dd>
                        </dl>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-8">
              <div className="mx-auto px-4 sm:px-6 lg:px-8">
                <h2 className="text-lg font-medium leading-6 text-gray-900">Overview</h2>
                <div className="mt-2 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
                  {/* Card */}
                  {cards.map((card) => (
                    <div key={card.name} className="overflow-hidden rounded-lg bg-white shadow">
                      <div className="p-5">
                        <div className="flex items-center">
                          <div className="flex-shrink-0">
                            <card.icon className="h-6 w-6 text-gray-400" aria-hidden="true" />
                          </div>
                          <div className="ml-5 w-0 flex-1">
                            <dl>
                              <dt className="text-sm font-medium leading-6 truncate text-gray-500">{card.name}</dt>
                              <dd>
                                <div className="text-4xl font-semibold tracking-tight text-gray-800">{card.amount}</div>
                              </dd>
                            </dl>
                          </div>
                        </div>
                      </div>
                      <div className="bg-gray-50 px-5 py-3">
                        <div className="text-sm">
                          <a href={card.href} className="font-medium text-cyan-700 hover:text-cyan-900">
                            View all
                          </a>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="mx-auto mt-8 px-4 sm:px-6 lg:px-8 w-fit lg:w-full">
              <h2 className="text-lg font-medium leading-6 text-gray-900 mb-2">Rows Processed</h2>
                <LineChart />
              </div>
              <h2 className="mx-auto mt-8 px-4 text-lg font-medium leading-6 text-gray-900 sm:px-6 lg:px-8">
                Recent activity
              </h2>

              {/* Activity list (smallest breakpoint only) */}
              <div className="shadow sm:hidden px-4">
                <ul className="mt-2 divide-y divide-gray-200 overflow-hidden shadow sm:hidden">
                  {transactions.map((transaction) => (
                    <li key={transaction.id}>
                      <a href={transaction.href} className="block bg-white px-4 py-4 hover:bg-gray-50">
                        <span className="flex items-center space-x-4">
                          <span className="flex flex-1 space-x-2 truncate">
                            <BanknotesIcon className="h-5 w-5 flex-shrink-0 text-gray-400" aria-hidden="true" />
                            <span className="flex flex-col truncate text-sm text-gray-500">
                              <span className="truncate">{transaction.name}</span>
                              <span>
                                <span className="font-medium text-gray-900">{transaction.amount}</span>{' '}
                                {transaction.currency}
                              </span>
                              <time dateTime={transaction.datetime}>{transaction.date}</time>
                            </span>
                          </span>
                          <ChevronRightIcon className="h-5 w-5 flex-shrink-0 text-gray-400" aria-hidden="true" />
                        </span>
                      </a>
                    </li>
                  ))}
                </ul>

                <nav
                  className="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3"
                  aria-label="Pagination"
                >
                  <div className="flex flex-1 justify-between">
                    <a
                      href="#"
                      className="relative inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                    >
                      Previous
                    </a>
                    <a
                      href="#"
                      className="relative ml-3 inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                    >
                      Next
                    </a>
                  </div>
                </nav>
              </div>
              {/* Activity table (small breakpoint and up) */}
              <div className="hidden sm:block">
                <div className="mx-auto px-4 sm:px-6 lg:px-8">
                  <div className="mt-2 flex flex-col">
                    <div className="min-w-full overflow-hidden overflow-x-auto align-middle shadow sm:rounded-lg">
                      {/* Pagination */}
                      <div className="bg-white shadow-md rounded-md overflow-hidden">
                      <table className="min-w-full divide-y divide-gray-200">
                        <thead>
                          <tr className="bg-gray-100 text-gray-600">
                            <th className="bg-gray-50 px-6 py-3 text-left text-sm font-semibold text-gray-900">Date</th>
                            <th className="bg-gray-50 px-6 py-3 text-left text-sm font-semibold text-gray-900">Workspace Member</th>
                            <th className="bg-gray-50 px-6 py-3 text-left text-sm font-semibold text-gray-900">Action</th>
                            <th className="bg-gray-50 px-6 py-3 text-left text-sm font-semibold text-gray-900">Resource Name</th>
                            <th className="bg-gray-50 px-6 py-3 text-left text-sm font-semibold text-gray-900">Resource Type</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 bg-white">
                          {activities.map((activity, index) => (
                            <tr key={index} className='bg-white'>
                              <td className="whitespace-nowrap px-6 py-4 text-left text-sm text-gray-500">{activity.date}</td>
                              <td className="font-medium text-gray-900 px-6 py-4 text-sm">{activity.member}</td>
                              <td className="font-medium text-gray-900 px-6 py-4 text-sm">{activity.action}</td>
                              <td className="font-medium text-gray-900 px-6 py-4 text-sm">{activity.resourceName}</td>
                              <td className="font-medium text-gray-900 px-6 py-4 text-sm">{activity.resourceType}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                      <nav
                        className="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6"
                        aria-label="Pagination"
                      >
                        <div className="hidden sm:block">
                          <p className="text-sm text-gray-700">
                            Showing <span className="font-medium">1</span> to <span className="font-medium">10</span> of{' '}
                            <span className="font-medium">20</span> results
                          </p>
                        </div>
                        <div className="flex flex-1 justify-between gap-x-3 sm:justify-end">
                          <a
                            href="#"
                            className="relative inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:ring-gray-400"
                          >
                            Previous
                          </a>
                          <a
                            href="#"
                            className="relative inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:ring-gray-400"
                          >
                            Next
                          </a>
                        </div>
                      </nav>
                    </div>
                  </div>
                </div>
              </div>
            </div>
      </main>
    </>
  );
};

export default Dashboard;
