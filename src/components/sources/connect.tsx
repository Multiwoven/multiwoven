import React from 'react';
import { Link, useNavigate } from 'react-router-dom';


export const SourceConnect = () => {
    const navigate = useNavigate();
    function setSSHTunnelFormState() {
        let sshToggleBtn = (document.getElementById("ssh") as HTMLInputElement);
        let sshForm = (document.getElementById("ssh-form") as HTMLInputElement);

        if (sshToggleBtn.checked === true) {
            console.log("Show Form");
            sshForm.style.display = "block";
        } else {
            console.log("Hide Form");
            sshForm.style.display = "none";
        }
    }

    function handleSubmit(event:any) {
        event.preventDefault();
        
        const form = event.target;
        const formData = new FormData(form);
        
        const tunnelUsername = formData.get("tunnel-username");
        const tunnelPort = formData.get("tunnel-port");
        const tunnelHost = formData.get("tunnel-host");
        const hostname = formData.get("hostname");
        const username = formData.get("username");
        const password = formData.get("password");
        const database = formData.get("database-name");
        const port = formData.get("port");

        console.log(
            "Tunnel Username: " + tunnelUsername +
            ", Tunnel Port: " + tunnelPort +
            ", Tunnel Host: " + tunnelHost +
            ", Hostname: " + hostname +
            ", Username: " + username +
            ", Password: " + password +
            ", Database Name: " + database +
            ", Port: " + port
        );
        navigate("/sources")
    }

    return(
        <form onSubmit={handleSubmit}>
            <div className="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
                <h3 className="text-2xl font-semibold leading-6 text-gray-700">Connect Source</h3>
            </div>
        <div className="flex flex-col md:flex-row">
            <div className="w-full md:w-2/3 border-r p-4">
                <div className="w-2/3">
                    <div>
                        <label htmlFor="hostname" className="block text-sm font-medium leading-6 text-gray-900">
                            Hostname
                        </label>
                        <div className="mt-2">
                            <input
                            type="text"
                            name="hostname"
                            id="hostname"
                            placeholder='redshift-host.us-east-1.redshift.amazonaws.com'
                            className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                            required
                            />
                        </div>
                    </div>
                    <div className="mt-3 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                        <div className="sm:col-span-3">
                            <label htmlFor="username" className="block text-sm font-medium leading-6 text-gray-900">
                                Username
                            </label>
                            <div className="mt-2">
                                <input
                                type="text"
                                name="username"
                                id="username"
                                autoComplete="username"
                                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                required
                                />
                            </div>
                        </div>

                        <div className="sm:col-span-3">
                            <label htmlFor="password" className="block text-sm font-medium leading-6 text-gray-900">
                                Password
                            </label>
                            <div className="mt-2">
                                <input
                                type="password"
                                name="password"
                                id="password"
                                autoComplete="password"
                                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                required
                                />
                            </div>
                        </div>
                    </div>
                    <div className="mt-3 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                        <div className="sm:col-span-3">
                            <label htmlFor="port" className="block text-sm font-medium leading-6 text-gray-900">
                                Port
                            </label>
                            <div className="mt-2">
                                <input
                                type="text"
                                name="port"
                                id="port"
                                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                required
                                />
                            </div>
                        </div>

                        <div className="sm:col-span-3">
                            <label htmlFor="database-name" className="block text-sm font-medium leading-6 text-gray-900">
                                Database Name
                            </label>
                            <div className="mt-2">
                                <input
                                type="text"
                                name="database-name"
                                id="database-name"
                                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                required
                                />
                            </div>
                        </div>
                    </div>
                    <div className="mt-3 relative flex items-start">
                        <div className="flex h-6 items-center">
                            <input
                            id="ssh"
                            name="ssh"
                            type="checkbox"
                            onClick={setSSHTunnelFormState}
                            className="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600"
                            />
                        </div>
                        <div className="ml-3 text-sm leading-6">
                            <label htmlFor="ssh" className="font-medium text-gray-900">
                            Use SSH Tunnel
                            </label>
                        </div>
                    </div>
                    <div id="ssh-form" className='hidden'>
                        <div className='mt-5'>
                            <label htmlFor="tunnel-host" className="block text-sm font-medium leading-6 text-gray-900">
                                Tunnel Host
                            </label>
                            <div className="mt-2">
                                <input
                                type="text"
                                name="tunnel-host"
                                id="tunnel-host"
                                placeholder='bastion.example.com'
                                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                />
                            </div>
                        </div>
                        <div className="mt-3 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                            <div className="sm:col-span-3">
                                <label htmlFor="tunnel-username" className="block text-sm font-medium leading-6 text-gray-900">
                                    Tunnel Username
                                </label>
                                <div className="mt-2">
                                    <input
                                    type="text"
                                    name="tunnel-username"
                                    id="tunnel-username"
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                    />
                                </div>
                            </div>
                            <div className="sm:col-span-3">
                                <label htmlFor="tunnel-port" className="block text-sm font-medium leading-6 text-gray-900">
                                    Tunnel Port
                                </label>
                                <div className="mt-2">
                                    <input
                                    type="text"
                                    name="tunnel-port"
                                    id="tunnel-port"
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div className="w-full md:w-1/3 p-4 relative">
                <div className="border-b border-gray-100 px-4 py-6 sm:col-span-2 sm:px-0">
                    <dt className="text-sm font-medium leading-6 text-gray-900">Allowed IPs</dt>
                    <dd className="mt-1 text-sm leading-6 text-gray-700 sm:mt-2">
                        If your source is behind a firewall/private network, please add the following static IP addresses:
                    </dd>
                    <ul>
                        <li>1.234.567.89</li>
                        <li>12.34.567.890</li>
                    </ul>
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
                    <Link to="/sources">
                        <button 
                            className="bg-slate-200 px-4 py-1 mr-3 md:px-5 md:py-2 rounded hover:bg-slate-100 transition duration-200 text-gray-900"
                        >
                            Exit
                        </button>
                    </Link>
                    {/* <Link to="/Sources"> */}
                        <button 
                        className="bg-orange-600 text-white px-4 py-1 md:px-5 md:py-2 rounded hover:bg-orange-500 transition duration-200"
                        type='submit'
                        >
                        Save
                        </button>
                    {/* </Link> */}
                </div>
            </div>
        </div>
        </form>
    )
}