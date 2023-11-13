import { Link, useParams, useNavigate } from "react-router-dom"
import Braze from '../../assets/images/braze.svg'
import Klaviyo from '../../assets/images/klaviyo.svg'
import CleverTap from '../../assets/images/clevertap.png'

import { Breadcrumb } from "../common/breadcrumb"

export const DestinationShow = () => {
    const params = useParams();
    const id = params.id;

    const destinations = [
        {
            name:"production-master",
            appname:"Braze",
            icon:Braze,
            uuid:"123"
        },
        {
            name:"staging-beta",
            appname:"Klaviyo",
            icon:Klaviyo,
            uuid:"456" 
        },
        {
            name:"dev-sandbox",
            appname:"CleverTap",
            icon:CleverTap,
            uuid:"789"
        }
    ]
    
    const source = destinations.find((src) => src.uuid === id);

    const tabs = [
        { name: 'Configuration', href: '#', current: true },
    ]

    const values = {
        apikey:"9575t9875e9t87et987t987598tvgdfuygyunfgea87f",
    }

    function classNames(...classes:any) {
        return classes.filter(Boolean).join(' ')
    }

    const navigate = useNavigate();    

    return(
        <form>
            <div className="px-4 sm:px-6 lg:px-8">
                <div className="border-b flex border-gray-200 pb-5 sm:flex sm:items-center">
                    {/* <h3 className="text-lg font-semibold leading-6 text-gray-500">
                        Sources / 
                    </h3>
                    <p className="text-lg font-semibold leading-6 text-gray-900 ml-2">{source?.name}</p> */}
                    <Breadcrumb customName={source?.appname} id={source?.uuid} />
                </div>
                <div className="min-w-0 flex-1 mt-3">
                    <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-2xl sm:tracking-tight">{source?.name}</h2>
                    <div className="mt-1 flex flex-col sm:mt-0 sm:flex-row sm:flex-wrap sm:space-x-6">
                        <div className="mt-2 flex items-center text-sm font-medium text-gray-900">
                            <img src={source?.icon} className="mr-1.5 h-5 w-5 flex-shrink-0" alt={source?.name} />
                            {source?.appname}
                        </div>
                        <div className="mt-2 flex items-center text-sm font-medium text-gray-800">
                            Last Updated: 11/03/23
                        </div>

                    </div>
                </div>
                <div>
                    <div className="sm:hidden">
                        <label htmlFor="tabs" className="sr-only">
                        Select a tab
                        </label>
                        <select
                        id="tabs"
                        name="tabs"
                        className="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-orange-500 focus:outline-none focus:ring-orange-500 sm:text-sm"
                        defaultValue={tabs.find((tab) => tab.current)?.name}
                        >
                        {tabs.map((tab) => (
                            <option key={tab.name}>{tab.name}</option>
                        ))}
                        </select>
                    </div>
                    <div className="hidden sm:block mt-5 mb-5">
                        <div className="border-b border-gray-200">
                        <nav className="-mb-px flex space-x-8" aria-label="Tabs">
                            {tabs.map((tab) => (
                            <a
                                key={tab.name}
                                href={tab.href}
                                className={classNames(
                                tab.current
                                    ? 'border-orange-500 text-orange-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                                'whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium'
                                )}
                                aria-current={tab.current ? 'page' : undefined}
                            >
                                {tab.name}
                            </a>
                            ))}
                        </nav>
                        </div>
                    </div>
                </div>
                <div className="flex flex-col md:flex-row">
                    <div className="w-full md:w-2/3 border-r p-4">
                        <div className="w-2/3">
                            <label htmlFor="api-key" className="block text-sm font-medium leading-6 text-gray-900">
                                API KEY
                            </label>
                            <div className="mt-2">
                                <input
                                type="text"
                                name="api-key"
                                id="api-key"
                                autoComplete="api-key"
                                value={values.apikey}
                                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                />
                            </div>
                        </div>
                    </div>
                    <div className="w-full md:w-1/3 p-4 relative">
                        <div className='flex flex-col'>
                            <Link to="/destinations">
                                <button 
                                className="bg-orange-600 w-full text-white font-semibold px-4 py-1 md:px-5 md:py-2 rounded hover:bg-orange-500 transition duration-200"
                                type="submit"
                                >
                                Save Changes
                                </button>
                            </Link>
                            <Link to="#">
                                <button 
                                className="bg-slate-200 px-4 w-full mt-3 py-1 mr-3 font-semibold md:px-5 md:py-2 rounded hover:bg-slate-100 transition duration-200 text-gray-900"
                                >
                                    Test Connection
                                </button>
                            </Link>
                        </div>
                        <div className="border-b border-gray-100 px-4 py-6 sm:col-span-2 sm:px-0">
                            <dt className="text-sm font-medium leading-6 text-gray-900">Read the Docs</dt>
                            <dd className="mt-1 text-sm leading-6 text-gray-700 sm:mt-2">
                            Fugiat ipsum ipsum deserunt culpa aute sint do nostrud anim incididunt cillum culpa consequat. Excepteur
                            qui ipsum aliquip consequat sint. Sit id mollit nulla mollit nostrud in ea officia proident. Irure nostrud
                            pariatur mollit ad adipisicing reprehenderit deserunt qui eu.
                            </dd>
                        </div>
                        <div className="border-t border-gray-100 px-4 py-6 sm:col-span-2 sm:px-0">
                            <dt className="text-sm font-medium leading-6 text-gray-900">Contact Support</dt>
                            <dd className="mt-1 text-sm leading-6 text-gray-700 sm:mt-2">
                            Fugiat ipsum ipsum deserunt culpa aute sint do nostrud anim incididunt cillum culpa consequat. Excepteur
                            qui ipsum aliquip consequat sint. Sit id mollit nulla mollit nostrud in ea officia proident. Irure nostrud
                            pariatur mollit ad adipisicing reprehenderit deserunt qui eu.
                            </dd>
                        </div>
                    </div>
                </div>
            </div>
        </form>
    )
}