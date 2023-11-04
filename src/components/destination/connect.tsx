import React, { useState } from 'react';
import Braze from '../../assets/images/braze.svg'
import Klaviyo from '../../assets/images/klaviyo.svg'
import CleverTap from '../../assets/images/clevertap.png'
import { Link } from 'react-router-dom';


export const DestinationConnect = () => {
    // Define the Destination type
    type Destination = {
        name: string;
        imageUrl: string; 
        category: string;    
    };

    const destinations: Destination[] = [
        {
            name: "Braze",
            imageUrl: Braze,  
            category: "Marketing"
        },
        {
            name: "Klaviyo",
            imageUrl: Klaviyo,  
            category: "Marketing"
        },
        {
            name: "CleverTap",
            imageUrl: CleverTap,
            category: "Marketing"
        }
    ];

    const [selectedDestination, setSelectedDestination] = useState<Destination>(destinations[0]);  
    return(
        <>
            <div className="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
                <h3 className="text-2xl font-semibold leading-6 text-gray-700">Connect Destination</h3>
            </div>
        <div className="flex flex-col md:flex-row">
            <div className="w-full md:w-2/3 border-r p-4">
            <form>
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
                        className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                        />
                    </div>
                </div>
            </form>
            </div>
            <div className="w-full md:w-1/3 p-4 relative">
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
                
                <div className='flex justify-end'>
                    <Link to="/destinations">
                        <button 
                            className="bg-slate-200 px-4 py-1 mr-3 md:px-5 md:py-2 rounded hover:bg-slate-100 transition duration-200 text-gray-900"
                        >
                            Exit
                        </button>
                    </Link>
                    <Link to="/destinations">
                        <button 
                        className="bg-orange-600 text-white px-4 py-1 md:px-5 md:py-2 rounded hover:bg-orange-500 transition duration-200"
                        >
                        Save
                        </button>
                    </Link>
                </div>
            </div>
        </div>
        </>
    )
}