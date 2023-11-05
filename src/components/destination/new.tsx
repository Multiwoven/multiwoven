import React, { useState } from 'react';
import Braze from '../../assets/images/braze.svg'
import Klaviyo from '../../assets/images/klaviyo.svg'
import CleverTap from '../../assets/images/clevertap.png'
import { Link } from 'react-router-dom';

// Define the Destination type
type Destination = {
    name: string;
    imageUrl: string; 
    category: string;    
};

const DestinationSelector: React.FC = () => {
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

    const [selectedDestination, setSelectedDestination] = useState<Destination>(destinations[0]);  // Default to first destination

    return (
        <>
            <div className="px-4 sm:px-6 lg:px-8">
                <div className="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
                    <h3 className="text-2xl font-semibold leading-6 text-gray-700">Select Destination</h3>
                </div>
                <div className="flex flex-col md:flex-row">
                    <div className="w-full md:w-1/3 border-r p-4">
                        <ul>
                        {destinations.map((destination) => (
                                <li key={destination.name} className="flex gap-x-2 md:gap-x-4 py-3 md:py-5 cursor-pointer hover:bg-stone-100" onClick={() => setSelectedDestination(destination)}>
                                    <img className="h-8 w-8 md:h-8 md:w-8 flex-none rounded-full bg-gray-50" src={destination.imageUrl} alt="" />
                                    <div className="min-w-0">
                                        <p className="text-xs md:text-sm font-semibold leading-5 md:leading-6 text-gray-900">{destination.name}</p>
                                    </div>
                                </li>
                            ))}
                        </ul>
                    </div>
                    <div className="w-full md:w-2/3 p-4 relative">
                        <div className='flex'>
                            <img className="h-6 w-6 md:h-8 md:w-7 flex-none rounded-full bg-gray-50 mr-2 md:mr-3" src={selectedDestination.imageUrl} alt="" />
                            <h2 className="text-xl md:text-2xl font-semibold mb-4 md:mb-5">{selectedDestination.name}</h2>
                        </div>
                        <h3 className="text-xs md:text-sm font-semibold leading-5 md:leading-6 text-gray-500 mb-2 md:mb-3">ABOUT</h3>
                        <p className="text-xs md:text-sm font-light mb-4 md:mb-5 text-gray-700">Build better campaigns on {selectedDestination.name} with up-to-date customer data from your data warehouse.</p>

                        <h3 className="text-xs md:text-sm font-semibold leading-5 md:leading-6 text-gray-500 mb-2 md:mb-3">FEATURES</h3>
                        <ul className="list-disc pl-4 md:pl-5 mb-4 md:mb-5 text-xs md:text-sm font-light text-gray-700">
                            <li>Sync data about users and accounts into {selectedDestination.name} to build hyper-personalized campaigns.</li>
                            <li>Automatically update your {selectedDestination.name} segments with fresh data from your warehouse.</li>
                            <li>Deliver better experiences by bringing in data from other customer touchpoints into {selectedDestination.name}.</li>
                        </ul>
                        <div className='flex justify-end'>
                            <Link to="/destinations">
                                <button 
                                    className="bg-slate-200 px-4 py-1 mr-3 md:px-5 md:py-2 rounded hover:bg-slate-100 transition duration-200 text-gray-900"
                                >
                                    Exit
                                </button>
                            </Link>
                            <Link to="/destinations/connect">
                                <button 
                                className="bg-orange-600 text-white px-4 py-1 md:px-5 md:py-2 rounded hover:bg-orange-500 transition duration-200"
                                >
                                Continue
                                </button>
                            </Link>
                        </div>
                    </div>
                </div>
            </div>
        </>
    );
}

export default DestinationSelector;
