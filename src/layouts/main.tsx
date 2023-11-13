import { Fragment, useState } from 'react'
import { Outlet, Link } from "react-router-dom";
import { Dialog, Menu, Transition } from '@headlessui/react'
import {
  Bars3Icon,
  BellIcon,
  CircleStackIcon,
  TableCellsIcon,
  ChartBarSquareIcon,
  BookOpenIcon,
  ArrowPathIcon,
  HomeIcon,
  XMarkIcon,
  CogIcon,
  ShieldCheckIcon,
  UserGroupIcon,
} from '@heroicons/react/24/outline'
import { ChevronDownIcon, MagnifyingGlassIcon } from '@heroicons/react/20/solid'
import MultiwovenLogo from '../assets/images/multiwoven-logo.png'
import { useLocation } from 'react-router-dom';

export const Layout =()=> {
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false)
  
  const navigation = [
    { name: 'Dashboard', to: '/', icon: HomeIcon, current: location.pathname === '/' },
    { name: 'Sources', to: '/sources', icon: CircleStackIcon, current: location.pathname === '/sources' || location.pathname === '/sources/new' || location.pathname === '/sources/connect' },
    { name: 'Destinations', to: '/destinations', icon: TableCellsIcon, current: location.pathname === '/destinations' || location.pathname === '/destinations/new' || location.pathname === '/destinations/connect' },
    { name: 'Models', to: '/models', icon: ChartBarSquareIcon, current: location.pathname === '/models' },
    { name: 'Syncs', to: '#', icon: ArrowPathIcon, current: location.pathname === '/syncs' },
    { name: 'Audiences', to: '#', icon: UserGroupIcon, current: location.pathname === '/audiences' },
  ]
  
  const secondaryNavigation = [
    { name: 'Settings', to: '/settings', new: false, icon: CogIcon, current: location.pathname === '/settings'  },
    { name: 'Documentation', to: 'https://www.docs.blue.com/', new: true, icon: BookOpenIcon, current: false  },
    { name: 'Privacy', to: '#', new: false, icon: ShieldCheckIcon, current: location.pathname === '/privacy'  },
  ]
  
  const userNavigation = [
    { name: 'Your profile', to: '#' },
    { name: 'Sign out', to: '#' },
  ]
  
  function classNames(...classes :any) {
    return classes.filter(Boolean).join(' ')
  }

  return (
    <>
      <div className='flex-1 bg-white'>
      <Transition.Root show={sidebarOpen} as={Fragment}>
          <Dialog as="div" className="relative z-40 lg:hidden border-r-2" onClose={setSidebarOpen}>
            <Transition.Child
              as={Fragment}
              enter="transition-opacity ease-linear duration-300"
              enterFrom="opacity-0"
              enterTo="opacity-100"
              leave="transition-opacity ease-linear duration-300"
              leaveFrom="opacity-100"
              leaveTo="opacity-0"
            >
              <div className="fixed inset-0 bg-gray-600 bg-opacity-75" />
            </Transition.Child>

            <div className="fixed inset-0 z-40 flex">
              <Transition.Child
                as={Fragment}
                enter="transition ease-in-out duration-300 transform"
                enterFrom="-translate-x-full"
                enterTo="translate-x-0"
                leave="transition ease-in-out duration-300 transform"
                leaveFrom="translate-x-0"
                leaveTo="-translate-x-full"
              >
                <Dialog.Panel className="relative flex w-full max-w-xs flex-1 flex-col bg-white pb-4 pt-5">
                  <Transition.Child
                    as={Fragment}
                    enter="ease-in-out duration-300"
                    enterFrom="opacity-0"
                    enterTo="opacity-100"
                    leave="ease-in-out duration-300"
                    leaveFrom="opacity-100"
                    leaveTo="opacity-0"
                  >
                    <div className="absolute right-0 top-0 -mr-12 pt-2">
                      <button
                        type="button"
                        className="relative ml-1 flex h-10 w-10 items-center justify-center rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                        onClick={() => setSidebarOpen(false)}
                      >
                        <span className="absolute -inset-0.5" />
                        <span className="sr-only">Close sidebar</span>
                        <XMarkIcon className="h-6 w-6 text-blue-900" aria-hidden="true" />
                      </button>
                    </div>
                  </Transition.Child>
                  <div className="flex flex-shrink-0 items-center px-4">
                    <img
                      className="h-7 w-auto mx-auto"
                      src={MultiwovenLogo}
                      alt="Multiwoven logo"
                    />
                  </div>
                  <nav
                    className="mt-5 h-full flex-shrink-0 divide-y divide-gray-800 overflow-y-auto"
                    aria-label="Sidebar"
                  >
                    <div className="space-y-1 px-2">
                      {navigation.map((item) => (
                        <Link
                          key={item.name}
                          to={item.to}
                          className={classNames(
                            item.current
                              ? 'bg-blue-100 text-blue-900'
                              : 'text-gray-600 hover:bg-blue-100 hover:text-blue-900',
                            'group flex items-center rounded-md px-2 py-2 text-base font-medium'
                          )}
                          aria-current={item.current ? 'page' : undefined}
                        >
                          <item.icon className="mr-4 h-6 w-6 flex-shrink-0" aria-hidden="true" />
                          {item.name}
                       </Link>
                      ))}
                    </div>
                    <div className="mt-6 pt-6">
                      <div className="space-y-1 px-2">
                        {secondaryNavigation.map((item) => (
                          <Link
                            key={item.name}
                            to={item.to}
                            target={item.new ? "_blank" : "_self"}
                            rel={item.new ? "noopener noreferrer" : ""}
                            className={classNames(
                              item.current
                                ? 'bg-blue-100 text-blue-900'
                                : 'text-gray-600 hover:bg-blue-100 hover:text-blue-900',
                              'group flex items-center rounded-md px-2 py-2 text-base font-medium'
                            )}
                          >
                            <item.icon className="mr-4 h-6 w-6" aria-hidden="true" />
                            {item.name}
                         </Link>
                        ))}
                      </div>
                    </div>
                  </nav>
                </Dialog.Panel>
              </Transition.Child>
              <div className="w-14 flex-shrink-0" aria-hidden="true">
                {/* Dummy element to force sidebar to shrink to fit close icon */}
              </div>
            </div>
          </Dialog>
        </Transition.Root>

        {/* Static sidebar for desktop */}
        <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col border-r">
          {/* Sidebar component, swap this element with another sidebar if you like */}
          <div className="flex flex-grow flex-col overflow-y-auto bg-white pb-4 pt-5">
            <div className="flex flex-shrink-0 items-center px-4">
              <img
                className="h-7 w-auto mx-auto"
                src={MultiwovenLogo}
                alt="Multiwoven logo"
              />
            </div>
            <nav className="mt-5 flex flex-1 flex-col overflow-y-auto" aria-label="Sidebar">
              <div className="space-y-1 px-2">
                {navigation.map((item) => (
                  <Link
                    key={item.name}
                    to={item.to}
                    className={classNames(
                      item.current ? 'bg-blue-100 text-blue-900' : 'text-gray-600 hover:bg-blue-100 hover:text-blue-900',
                      'group flex items-center rounded-md px-2 py-2 text-base font-medium leading-6 mb-2'
                    )}
                    aria-current={item.current ? 'page' : undefined}
                  >
                    <item.icon className="mr-4 h-6 w-6 flex-shrink-0" aria-hidden="true" />
                    {item.name}
                 </Link>
                ))}
              </div>
              
              <div className="mt-6 pt-6">
                <div className="space-y-1 px-2">
                {secondaryNavigation.map((item) => (
                  <Link
                    key={item.name}
                    to={item.to}
                    target={item.new ? "_blank" : "_self"}
                    rel={item.new ? "noopener noreferrer" : ""}
                    className={classNames(
                      item.current
                        ? 'bg-blue-100 text-blue-900'
                        : 'text-gray-600 hover:bg-blue-100 hover:text-blue-900',
                      'group flex items-center rounded-md px-2 py-2 text-base font-medium mb-2'
                    )}
                  >
                    <item.icon className="mr-4 h-6 w-6" aria-hidden="true" />
                    {item.name}
                 </Link>
                ))}
                </div>
              </div>
            </nav>
          </div>
        </div>

        <div className="lg:pl-72">
          <div className="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
            <button type="button" className="-m-2.5 p-2.5 lg:hidden" onClick={() => setSidebarOpen(true)}>
              <span className="sr-only">Open sidebar</span>
              <Bars3Icon className="h-6 w-6" aria-hidden="true" />
            </button>

            {/* Separator */}
            <div className="h-6 w-px bg-gray-200 lg:hidden" aria-hidden="true" />

            <div className="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
              <form className="relative flex flex-1" action="#" method="GET">
                <label htmlFor="search-field" className="sr-only">
                  Search
                </label>
                <MagnifyingGlassIcon
                  className="pointer-events-none absolute inset-y-0 left-0 h-full w-5 text-gray-400"
                  aria-hidden="true"
                />
                <input
                  id="search-field"
                  className="block h-full w-full border-0 py-0 pl-8 pr-0 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm"
                  placeholder="Search..."
                  type="search"
                  name="search"
                />
              </form>
              <div className="flex items-center gap-x-4 lg:gap-x-6">
                <button type="button" className="-m-2.5 p-2.5 text-gray-400 hover:text-gray-500">
                  <span className="sr-only">View notifications</span>
                  <BellIcon className="h-6 w-6" aria-hidden="true" />
                </button>

                {/* Separator */}
                <div className="hidden lg:block lg:h-6 lg:w-px lg:bg-gray-200" aria-hidden="true" />

                {/* Profile dropdown */}
                <Menu as="div" className="relative">
                  <Menu.Button className="-m-1.5 flex items-center p-1.5">
                    <span className="sr-only">Open user menu</span>
                    <img
                      className="h-8 w-8 rounded-full bg-gray-50"
                      src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                      alt=""
                    />
                    <span className="hidden lg:flex lg:items-center">
                      <span className="ml-4 text-sm font-semibold leading-6 text-gray-900" aria-hidden="true">
                        John Doe
                      </span>
                      <ChevronDownIcon className="ml-2 h-5 w-5 text-gray-400" aria-hidden="true" />
                    </span>
                  </Menu.Button>
                  <Transition
                    as={Fragment}
                    enter="transition ease-out duration-100"
                    enterFrom="transform opacity-0 scale-95"
                    enterTo="transform opacity-100 scale-100"
                    leave="transition ease-in duration-75"
                    leaveFrom="transform opacity-100 scale-100"
                    leaveTo="transform opacity-0 scale-95"
                  >
                    <Menu.Items className="absolute right-0 z-10 mt-2.5 w-32 origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-gray-900/5 focus:outline-none">
                      {userNavigation.map((item) => (
                        <Menu.Item key={item.name}>
                          {({ active }) => (
                            <Link
                              to={item.to}
                              className={classNames(
                                active ? 'bg-gray-50' : '',
                                'block px-3 py-1 text-sm leading-6 text-gray-900'
                              )}
                            >
                              {item.name}
                           </Link>
                          )}
                        </Menu.Item>
                      ))}
                    </Menu.Items>
                  </Transition>
                </Menu>
              </div>
            </div>
          </div>

          <main className="py-10">
            <div className="px-4 sm:px-6 lg:px-8">
            <Outlet />
            </div>
          </main>
        </div>
      </div>
    </>
  )
}
