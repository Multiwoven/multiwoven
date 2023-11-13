import { Link, useParams, useNavigate } from "react-router-dom"
import AWS from '../../assets/images/redshift.svg'
import Flake from '../../assets/images/snowflake.png'
import Query from '../../assets/images/big-query.png'
import Databricks from '../../assets/images/databricks.png'
import { Breadcrumb } from "../common/breadcrumb"

export const SourceShow = () => {
    const params = useParams();
    const id = params.id;

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
            appname:"Big Query"
        }, {
            name: "Databricks",
            uuid:"1278297386",
            icon: Databricks,
            database: "dev",
            connected: "10 days",
            appname:"Databricks"
        }
    ]
    
    const source = sources.find((src) => src.uuid === id);

    const tabs = [
        { name: 'Configuration', href: '#', current: true },
    ]

    const values = {
        hostname:source?.appname + "-host.us-east-1." + source?.appname + ".amazonaws.com",
        username:"admin",
        password:"123456",
        port:"8080",
        dbname:"dev",
        tunnelHost:"redshift-host.us-east-1.redshift.amazonaws.com",
        tunnelUsername:"admin",
        tunnelPort:"8000"
    }

    function classNames(...classes:any) {
        return classes.filter(Boolean).join(' ')
    }

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
                        <div>
                            <label htmlFor="hostname" className="block text-sm font-medium leading-6 text-gray-900">
                                Hostname
                            </label>
                            <div className="mt-2">
                                <input
                                type="text"
                                name="hostname"
                                id="hostname"
                                value={values.hostname}
                                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
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
                                    value={values.username}
                                    autoComplete="username"
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
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
                                    value={values.password}
                                    autoComplete="password"
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
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
                                    value={values.port}
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
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
                                    value={values.dbname}
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
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
                                className="h-4 w-4 rounded border-gray-300 text-orange-600 focus:ring-orange-600"
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
                                    value={values.tunnelHost}
                                    className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
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
                                        value={values.tunnelUsername}
                                        className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
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
                                        value={values.tunnelPort}
                                        className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div className="w-full md:w-1/4 p-4 relative">
                        <div className='flex flex-col'>
                            <Link to="/sources">
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