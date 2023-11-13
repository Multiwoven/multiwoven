import { Fragment } from 'react'
import { PlusIcon } from '@heroicons/react/20/solid'
import { Link, useNavigate } from 'react-router-dom'

import AWS from '../../assets/images/redshift.svg'
import Flake from '../../assets/images/snowflake.png'
import Query from '../../assets/images/big-query.png'
import Databricks from '../../assets/images/databricks.png'
import { Breadcrumb } from '../common/breadcrumb'


export const Sources = () => {

    const sources = [
        {
            name: 'Amazon Redshift',
            uuid:"1278297389",
            icon: AWS,
            database: "dev",
            connected: "14 days",
            appname:"Redshift"
        }, {
            name: 'Snowflake',
            uuid:"1278297388",
            icon: Flake,
            database: "dev",
            connected: "2 days",
            appname:"Snowflake"
        }, {
            name: "Google BigQuery",
            uuid:"1278297387",
            icon: Query,
            database: "dev",
            connected: "23 days",
            appname:"BigQuery"
        }, {
            name: "Databricks",
            uuid:"1278297386",
            icon: Databricks,
            database: "dev",
            connected: "10 days",
            appname:"Databricks"
        }
    ]

    const navigate = useNavigate();

    function handleSourceOpen(uuid:string) {
        navigate("/sources/show/" + uuid)
    }

    if (sources) {
        return(
            <>
                <div className="px-4 sm:px-6 lg:px-8">
                    <div className="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
                        {/* <h3 className="text-2xl font-semibold leading-6 text-gray-700">Sources</h3> */}
                        <Breadcrumb />
                        <div className="mt-3 sm:ml-4 sm:mt-0">
                            <Link to="/sources/new">
                            <button
                            type="button"
                            className="inline-flex items-center rounded-md bg-orange-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-orange-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                            >
                                <PlusIcon className="h-5 w-5 mr-1" aria-hidden="true" />
                                Source
                            </button>
                            </Link>
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
                                        <th scope="col" className="px-1 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            Database
                                        </th>
                                        <th scope="col" className="px-1 py-3.5 text-left text-sm font-semibold text-gray-900">
                                            Last Updated
                                        </th>
                                        <th scope="col" className="px-1 py-3.5 text-right text-sm font-semibold text-gray-900">
                                            Status
                                        </th>
                                    </tr>
                                </thead>
                                    <tbody className="divide-y divide-gray-200 bg-white">
                                        {sources.map((source) => (
                                        <tr key={source.name} onClick={() => handleSourceOpen(source.uuid)} className='cursor-pointer'>
                                            <td className="whitespace-nowrap py-5 pl-4 pr-3 text-sm sm:pl-0">
                                            <div className="flex items-center">
                                                <div className="h-8 w-8 flex-shrink-0">
                                                <img className="h-8 w-8 md:h-8 md:w-8 flex-none rounded-full bg-gray-50" src={source.icon} alt="" />
                                                </div>
                                                <div className="ml-4">
                                                <div className="font-medium text-gray-900">{source.name}</div>
                                                </div>
                                            </div>
                                            </td>
                                            <td className="whitespace-nowrap  text-sm text-gray-500 text-left">
                                                <div className="text-gray-900">{source.database}</div>
                                                <div className="mt-1 text-gray-500">Connected {source.connected} ago</div>
                                            </td>
                                            <td className="whitespace-nowrap px-1 py-5 text-sm text-gray-500 text-left">
                                                11/03/23
                                            </td>
                                            <td className="whitespace-nowrap px-1 py-5 text-sm text-gray-500 text-right">
                                                <span className="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                                                    Active
                                                </span>
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
                <h3 className="mt-2 text-sm font-semibold text-gray-900">No sources</h3>
                <p className="mt-1 text-sm text-gray-500">Get started by creating a Add Source.</p>
                <div className="mt-6">
                    <Link to="/sources/new">
                    <button
                        type="button"
                        className="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    >
                        <PlusIcon className="-ml-0.5 mr-1.5 h-5 w-5" aria-hidden="true" />
                        Add Source
                    </button>
                    </Link>
                </div>
            </div>
            </>
          )  
        }
}