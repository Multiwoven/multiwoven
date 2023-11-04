import React, { useState } from 'react';
import Braze from '../../assets/images/braze.svg'
import Klaviyo from '../../assets/images/klaviyo.svg'
import CleverTap from '../../assets/images/clevertap.webp'

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
        <div className="flex flex-col md:flex-row">
            <div className="w-full md:w-1/3 border-r p-4">
                <ul>
                {destinations.map((destination) => (
                        <li key={destination.name} className="flex gap-x-2 md:gap-x-4 py-3 md:py-5 cursor-pointer hover:bg-stone-100" onClick={() => setSelectedDestination(destination)}>
                            <img className="h-10 w-10 md:h-12 md:w-12 flex-none rounded-full bg-gray-50" src={destination.imageUrl} alt="" />
                            <div className="min-w-0">
                                <p className="text-xs md:text-sm font-semibold leading-5 md:leading-6 text-gray-900">{destination.name}</p>
                                <p className="mt-1 truncate text-xs leading-5 text-gray-500">{destination.category}</p>
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
                <button 
                    className="absolute right-4 bg-indigo-600 text-white px-4 py-1 md:px-5 md:py-2 rounded hover:bg-indigo-500 transition duration-200"
                >
                    Continue
                </button>
            </div>
        </div>
    );
}

export default DestinationSelector;
