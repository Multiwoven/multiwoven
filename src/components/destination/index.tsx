import { Fragment, useRef, useState } from 'react'
import { PlusIcon } from '@heroicons/react/20/solid'

import Braze from '../../assets/images/braze.svg'
import Klaviyo from '../../assets/images/klaviyo.svg'
import CleverTap from '../../assets/images/clevertap.png'

export const Destination = () => {

    const destinations = [
        {
            name:"Braze",
            icon:Braze   
        },
        {
            name:"Klaviyo",
            icon:Klaviyo   
        },
        {
            name:"CleverTap",
            icon:CleverTap
        }
    ]

    if (destinations) {
        return(
            <>
            <div className="px-4 sm:px-6 lg:px-8">
                <div className="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
                    <h3 className="text-base font-semibold leading-6 text-gray-900">Destinations</h3>
                    <div className="mt-3 sm:ml-4 sm:mt-0">
                        <button
                        type="button"
                        className="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                        >
                        New Destination
                        </button>
                    </div>
                </div>
                <div className="mt-8 flow-root">
                    <div className="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                    <div className="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                        <table className="min-w-full divide-y divide-gray-300">
                        <thead>
                            <tr>
                                <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">
                                    Name
                                </th>
                                <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                    Status
                                </th>
                                <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                                    Last Updated
                                </th>
                                <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-0">
                                    <span className="sr-only">Edit</span>
                                </th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 bg-white">
                            {destinations.map((destination) => (
                            <tr key={destination.name}>
                                <td className="whitespace-nowrap py-5 pl-4 pr-3 text-sm sm:pl-0">
                                <div className="flex items-center">
                                    <div className="h-11 w-11 flex-shrink-0">
                                    <img className="h-10 w-10 rounded-lg" src={destination.icon} alt="" />
                                    </div>
                                    <div className="ml-4">
                                    <div className="font-medium text-gray-900">{destination.name}</div>
                                    </div>
                                </div>
                                </td>
                                <td className="whitespace-nowrap px-3 py-5 text-sm text-gray-500">
                                    <span className="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                                        Active
                                    </span>
                                </td>
                                <td className="whitespace-nowrap px-3 py-5 text-sm text-gray-500">
                                    <p className='font-semibold'>11/03/23</p>
                                </td>
                                <td className="relative whitespace-nowrap py-5 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                                    <a href="#" className="text-indigo-600 hover:text-indigo-900 mr-2">
                                        {/* Edit<span className="sr-only">, {person.name}</span> */}
                                        <button
                                            type="button"
                                            className="rounded-md bg-indigo-50 px-2.5 py-1.5 mr-2 text-sm font-semibold text-indigo-600 shadow-sm hover:bg-indigo-100"
                                        >
                                            Edit
                                        </button>
                                    </a>
                                </td>
                            </tr>
                            ))}
                        </tbody>
                        </table>
                    </div>
                    </div>
                </div>
                </div>
            </>
        )
        } else{
          return (
            <>
            <div className="text-center">
                <svg
                    className="mx-auto h-12 w-12 text-gray-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    aria-hidden="true"
                >
                    <path
                        vectorEffect="non-scaling-stroke"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z"
                    />
                </svg>
                <h3 className="mt-2 text-sm font-semibold text-gray-900">No Destinations</h3>
                <p className="mt-1 text-sm text-gray-500">Get started by creating a new destination.</p>
                <div className="mt-6">
                    <button
                        type="button"
                        className="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    >
                        <PlusIcon className="-ml-0.5 mr-1.5 h-5 w-5" aria-hidden="true" />
                        New Destination
                    </button>
                </div>
            </div>
            </>
          )  
        }
}