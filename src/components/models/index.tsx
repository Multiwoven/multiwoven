import { PlusIcon } from '@heroicons/react/20/solid'

import Flake from '../../assets/images/snowflake.png'

import { Link, useNavigate } from 'react-router-dom'
import { Breadcrumb } from '../common/breadcrumb'

export const Models = () => {
    const models = [
        {
            model_name: 'Contacts',
            uuid:"1278297388",
            icon: Flake,
            database: "dev",
            connected: "2 days",
            appname:"Snowflake",
            tags:[
                {
                    id:"1",
                    value:"us-west-1",
                    color:"orange"
                }, {
                    id:"12",
                    value: "production",
                    color:"green"
                }
            ]
        }, {
            model_name: 'Locations',
            uuid:"1278297399",
            icon: Flake,
            database: "dev",
            connected: "2 days",
            appname:"Snowflake",
            tags:[
                {
                    id:"2",
                    value:"us-central-1",
                    color:"orange"
                }, {
                    id:"22",
                    value: "sandbox",
                    color:"green"
                }, {
                    id:"23",
                    value: "dev",
                    color:"yellow"
                }
            ]
        },{
            model_name: 'Products',
            uuid:"1278297300",
            icon: Flake,
            database: "dev",
            connected: "2 days",
            appname:"Snowflake",
            tags:[
                {
                    id:"3",
                    value:"us-east-1",
                    color:"orange"
                }, {
                    id:"32",
                    value: "deployment",
                    color:"green"
                }
            ]
        },
    ]

    const navigate = useNavigate();

    
    function handleModelOpen(uuid:string) {
        navigate("/models/show/" + uuid)
    }

    if (models) {
        return(
            <>
            <div className="px-4 sm:px-6 lg:px-8">
                <div className="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
                    <Breadcrumb />
                    <div className="mt-3 sm:ml-4 sm:mt-0">
                        <Link to="/models/new">
                        <button
                        type="button"
                        className="inline-flex items-center rounded-md bg-orange-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-orange-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                        >
                            <PlusIcon className="h-5 w-5 mr-1" aria-hidden="true" />
                            Model
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
                                    Type
                                </th>
                                <th scope="col" className="px-1 py-3.5 text-left text-sm font-semibold text-gray-900">
                                    Last Updated
                                </th>
                                <th scope="col" className="px-1 w-1/5 py-3.5 text-left text-sm font-semibold text-gray-900">
                                    Status
                                </th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 bg-white">
                            {models.map((model) => (
                            <tr key={model.model_name} onClick={() => handleModelOpen(model.uuid)} className='cursor-pointer'>
                                <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                                    {model.model_name}
                                </td>
                                <td className="whitespace-nowrap py-5 pl-4 pr-3 text-sm sm:pl-0">
                                    <div className="flex items-center">
                                        <div className="h-8 w-8 flex-shrink-0">
                                        <img className="h-8 w-8 rounded-lg" src={model.icon} alt="" />
                                        </div>
                                        <div className="ml-4">
                                        <div className="font-medium text-gray-900">{model.appname}</div>
                                        </div>
                                    </div>
                                </td>
                                <td className="whitespace-nowrap px-1 py-5 text-sm text-gray-500 text-left">
                                    11/03/23
                                </td>
                                    <td className="whitespace-nowrap px-1 py-5 text-sm text-gray-500 text-left">
                                        {model.tags.map((tag) => (
                                        <span className="inline-flex items-center mr-2 rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-700 ring-1 ring-inset ring-green-600/20">
                                            {tag.value}
                                        </span>
                                        ))}
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
                <h3 className="mt-2 text-sm font-semibold text-gray-900">No models</h3>
                <p className="mt-1 text-sm text-gray-500">Get started by creating a new model.</p>
                <div className="mt-6">
                    <Link to="/models/new">
                    <button
                        type="button"
                        className="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    >
                        <PlusIcon className="-ml-0.5 mr-1.5 h-5 w-5" aria-hidden="true" />
                        Add Model
                    </button>
                    </Link>
                </div>
            </div>
            </>
          )  
        }
}