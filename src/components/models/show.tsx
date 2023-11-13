import { Link, useParams, useNavigate } from "react-router-dom"
import Flake from '../../assets/images/snowflake.png'
import AceEditor from 'react-ace';

import "ace-builds/src-noconflict/mode-mysql";
import "ace-builds/src-noconflict/theme-github";
import "ace-builds/src-noconflict/ext-language_tools";

import { Breadcrumb } from "../common/breadcrumb"

export const ModelShow = () => {
    const params = useParams();
    const id = params.id;

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
    
    const source = models.find((src) => src.uuid === id);

    const tabs = [
        { name: 'SQL Query', href: '#', current: true },
        { name: 'History', href: '#', current: false },
        { name: 'Table Columns', href: '#', current: false },
    ]

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
                    <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-2xl sm:tracking-tight">{source?.model_name}</h2>
                    <div className="mt-1 flex flex-col sm:mt-0 sm:flex-row sm:flex-wrap sm:space-x-6">
                        <div className="mt-2 flex items-center text-sm font-medium text-gray-900">
                            <img src={source?.icon} className="mr-1.5 h-5 w-5 flex-shrink-0" alt={source?.model_name} />
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
                        <div className="border-b border-r border-l border-t border-gray-200 bg-white px-4 py-5 sm:px-6">
                            <div className="-ml-4 -mt-4 flex flex-wrap items-center justify-between sm:flex-nowrap">
                                <div className="ml-4 mt-4">
                                <div className="flex items-center">
                                    <div className="flex-shrink-0">
                                    <img
                                        className="h-8 rounded-full"
                                        src={source?.icon}
                                        alt=""
                                    />
                                    </div>
                                    <div className="ml-4">
                                    <h3 className="text-lg font-semibold leading-6 text-gray-900">{source?.appname}</h3>
                                    </div>
                                </div>
                                </div>
                                <div className="ml-4 mt-4 flex flex-shrink-0">
                                <button
                                    type="button"
                                    className="relative inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                                >
                                    <span>Edit</span>
                                </button>
                                </div>
                            </div>
                        </div>
                        <div className="border-b border-r border-l border-gray-200 bg-white px-1 py-2 sm:px-3">
                        <AceEditor
                            placeholder="select * from users;"
                            mode="mysql"
                            theme="github"
                            name="blah2"
                            fontSize={16}
                            showPrintMargin={false}
                            showGutter={true}
                            highlightActiveLine={false}
                            value={`SELECT * FROM users INNER JOIN locations ON users.user_id = locations.user_id;`}
                            width="max"
                            setOptions={{
                            enableBasicAutocompletion: false,
                            enableLiveAutocompletion: false,
                            enableSnippets: false,
                            showLineNumbers: true,
                            tabSize: 2,
                            readOnly: true,
                            }}/>
                        </div>
                    </div>
                    <div className="w-full md:w-1/3 p-4 relative">
                        <div className="px-4 sm:px-0">
                            <h3 className="text-sm font-medium text-gray-900">Primary Key</h3>
                                <select
                                    title="Primary Key"
                                    id="location"
                                    name="location"
                                    className="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                    defaultValue="users"
                                >
                                    <option>United States</option>
                                    <option>Canada</option>
                                    <option>Mexico</option>
                                </select>
                            </div>
                        </div>
                    </div>
            </div>
        </form>
    )
}