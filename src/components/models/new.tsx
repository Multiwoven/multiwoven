import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import AWS from '../../assets/images/redshift.svg'
import Flake from '../../assets/images/snowflake.png'
import Query from '../../assets/images/big-query.png'
import Databricks from '../../assets/images/databricks.png'
import { Breadcrumb } from '../common/breadcrumb';
import {
    CheckCircleIcon,
    ChevronRightIcon,
    CircleStackIcon,
  } from '@heroicons/react/20/solid'

const ModelSelector: React.FC = () => {
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

    return (
        <>
            <main className="px-4 sm:px-6 lg:px-8">
            <div className="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
                <Breadcrumb />
            </div>

            
            <ul className="mt-5 divide-y divide-gray-200 border-t border-gray-200 sm:mt-0 sm:border-t-0">
              {models.map((model) => (
                <li key={model.name}>
                  <Link to={"/models/new/" + model.uuid + "/method/"} className="group block">
                    <div className="flex items-center px-4 py-5 sm:px-0 sm:py-6">
                      <div className="flex min-w-0 flex-1 items-center">
                        <div className="flex-shrink-0">
                          <img
                            className="h-12 w-12 rounded-full group-hover:opacity-75"
                            src={model.icon}
                            alt=""
                          />
                        </div>
                        <div className="min-w-0 flex-1 px-4 md:grid md:grid-cols-2 md:gap-4">
                          <div>
                            <p className="truncate text-sm font-medium text-gray-900">{model.name}</p>
                            <p className="mt-2 flex items-center text-sm text-gray-500">
                              <CircleStackIcon className="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400" aria-hidden="true" />
                              <span className="truncate">{model.database}</span>
                            </p>
                          </div>
                          <div className="hidden md:block">
                            <div>
                              <p className="text-sm text-gray-900">
                                Connected <time dateTime={model.connected}>{model.connected}</time> ago
                              </p>
                              <p className="mt-2 flex items-center text-sm text-gray-500">
                                <CheckCircleIcon
                                  className="mr-1.5 h-5 w-5 flex-shrink-0 text-green-400"
                                  aria-hidden="true"
                                />
                                Active
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>
                      <div>
                        <ChevronRightIcon
                          className="h-5 w-5 text-gray-400 group-hover:text-gray-700"
                          aria-hidden="true"
                        />
                      </div>
                    </div>
                  </Link>
                </li>
              ))}
            </ul>
            </main>
        </>
    );
}

export default ModelSelector;
