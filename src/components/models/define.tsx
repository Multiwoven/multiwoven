import { Link, useParams, useNavigate } from "react-router-dom"
import Flake from '../../assets/images/snowflake.png'
import AWS from '../../assets/images/redshift.svg'
import Query from '../../assets/images/big-query.png'
import Databricks from '../../assets/images/databricks.png'
import AceEditor from 'react-ace';

import {ArrowPathIcon} from '@heroicons/react/24/outline'

import "ace-builds/src-noconflict/mode-mysql";
import "ace-builds/src-noconflict/theme-github";
import "ace-builds/src-noconflict/ext-language_tools";

import { Breadcrumb } from "../common/breadcrumb"
import { useState } from "react";

export const ModelDefine = () => {
    const [showPK, setShowPK] = useState<boolean>(false);
    const params = useParams();
    const id = params.id;

    const models = [
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
    
    const model = models.find((src) => src.uuid === id);
    const navigate = useNavigate();


    function getPrimaryKeys() {
        setShowPK(true);
    }

    function handleNewModel() {
        navigate("/models")
    }

    return(
        <form>
            <div className="px-4 sm:px-6 lg:px-8">
                <div className="border-b flex border-gray-200 pb-5 sm:flex sm:items-center">
                    <Breadcrumb customName={model?.appname} id={model?.uuid} />
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
                                        src={model?.icon}
                                        alt=""
                                    />
                                    </div>
                                    <div className="ml-4">
                                    <h3 className="text-lg font-semibold leading-6 text-gray-900">{model?.appname}</h3>
                                    </div>
                                </div>
                                </div>
                                <div className="ml-4 mt-4 flex flex-shrink-0">
                                <button
                                    type="button"
                                    className="relative inline-flex items-center rounded-md mr-2 bg-white px-3 py-2 text-sm font-medium text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                                >
                                    <span>Run Query</span>
                                </button>
                                <button
                                    type="button"
                                    className="relative inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-medium text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                                >
                                    <span>Beautify</span>
                                </button>
                                </div>
                            </div>
                        </div>
                        <div className="border-b border-r border-l h-64 border-gray-200 bg-white px-1 py-2 sm:px-3">
                            <AceEditor
                                placeholder="select * from users;"
                                mode="mysql"
                                theme="github"
                                name="query"
                                fontSize={16}
                                showPrintMargin={false}
                                showGutter={true}
                                highlightActiveLine={false}
                                width="max"
                                height="100%"
                                setOptions={{
                                enableBasicAutocompletion: false,
                                enableLiveAutocompletion: false,
                                enableSnippets: false,
                                showLineNumbers: true,
                                tabSize: 2,
                                readOnly: false,
                                }}/>
                        </div>
                        <div className="border-b border-r border-l border-t h-64 mt-3 border-gray-200 bg-white px-1 py-2 sm:px-3">
                            <h1 className="text-sm">Run your query to see the results</h1>
                        </div>
                    </div>
                    <div className="w-full md:w-1/3 p-4 relative">
                        <div className="px-4 sm:px-0">
                        <h3 className="text-sm font-medium text-gray-900">Primary Key</h3>
                            <div className="flex flex-row justify-around">
                                { showPK ?
                                    <select
                                    title="Primary Key"
                                    id="location"
                                    name="location"
                                    className="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-orange-600 sm:text-sm sm:leading-6"
                                    defaultValue="user_id"
                                    >
                                        <option>user_id</option>
                                        <option>username</option>
                                        <option>email</option>
                                    </select>
                                    :                                         
                                    <select
                                    title="Primary Key"
                                    id="primary-key"
                                    name="primaryKey"
                                    className="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-orange-600 sm:text-sm sm:leading-6" disabled
                                    defaultValue="--"
                                    >
                                        <option>--</option>
                                    </select> 
                                    }

                                <div
                                className="relative rounded-md ml-2 mt-2 h-fit p-2 bg-white text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-100"
                                onClick={getPrimaryKeys}
                                >
                                <ArrowPathIcon className="h-5" />
                                </div>
                            </div>
                        </div>
                        <div className="px-4 sm:px-0 mt-3">
                        <h3 className="text-sm font-medium text-gray-900">Model Name</h3>
                            <input
                                type="name"
                                name="modelName"
                                id="modelName"
                                className="mt-2 block w-full rounded-md border-0 p-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
                                placeholder="Model Name"
                            />
                        </div>
                        <button
                            type="button"
                            className="w-full rounded-md px-3 py-2 mt-4 text-sm font-semibold text-white shadow-sm ring-1 ring-inset ring-gray-300 bg-orange-500 hover:bg-orange-600"
                            disabled={!showPK}
                            onClick={handleNewModel}
                        >
                            <span>Save</span>
                        </button>
                    </div>
                </div>
            </div>
        </form>
    )
}