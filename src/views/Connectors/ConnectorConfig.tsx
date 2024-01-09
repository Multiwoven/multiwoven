import { getConnectorDefinition } from "@/services/common";
import { useEffect, useState } from "react";
import { useLocation, useParams } from "react-router-dom";

type ConnectionSpec = {
  documentation_url: string;
  connection_specification: {
    $schema: string;
    title: string;
    type: string;
    required: string[];
    properties: {
      credentials: {
        title: string;
        type: string;
        oneOf: Array<{
          title: string;
          type: string;
          required: string[];
          order: number;
          properties: {
            auth_type: {
              type: string;
              const: string;
              order: number;
            };
            username: {
              description: string;
              examples: string[];
              type: string;
              title: string;
              order: number;
            };
            password: {
              description: string;
              type: string;
              multiwoven_secret: boolean;
              title: string;
              order: number;
            };
          };
        }>;
        order: number;
      };
      host: {
        description: string;
        examples: string[];
        type: string;
        title: string;
        order: number;
      };
      role: {
        description: string;
        examples: string[];
        type: string;
        title: string;
        order: number;
      };
      warehouse: {
        description: string;
        examples: string[];
        type: string;
        title: string;
        order: number;
      };
      database: {
        description: string;
        examples: string[];
        type: string;
        title: string;
        order: number;
      };
      schema?: {
        description: string;
        examples: string[];
        type: string;
        title: string;
        order: number;
      };
      jdbc_url_params?: {
        description: string;
        title: string;
        type: string;
        order: number;
      };
    };
  };
};

type Credentials = {
  title: string;
  type: string;
  required: string[];
  order: number;
  properties: {
    auth_type: {
      type: string;
      const: string;
      order: number;
    };
    username: {
      description: string;
      examples: string[];
      type: string;
      title: string;
      order: number;
    };
    password: {
      description: string;
      type: string;
      multiwoven_secret: boolean;
      title: string;
      order: number;
    };
  };
};

export const ConnectorConfig = (props: any) => {
  const [connectorsSpecs, setConnectorsSpecs] = useState<Array<any>>([]);
  // console.log(props.connectorType);
  const location = useLocation();

  const queryParams = new URLSearchParams(location.search);
  const type = queryParams.get('type') || '';
  const name = queryParams.get('name') || '';

  useEffect(() => {  
    async function fetchData() {
      const connectorType = props.connectorType === "sources" ? "source" : "destination";
      console.log(props.connectorType,connectorType, type, name);
      
      const response = await getConnectorDefinition(type, name);
      console.log(response);
      setConnectorsSpecs(response?.data);
      // setConnectorsSpecs([""]);
    }

    fetchData();
  }, []);

  if (!connectorsSpecs) {
    return <>LOADING</>;
  }

  try {
    // const data: ConnectionSpec = JSON.parse(localStorage.getItem("JSON") || "");
    const data:any = connectorsSpecs;

    const renderInputField = (property:any, key:any) => {
      const inputType = property.multiwoven_secret ? "password" : "text"; // Determine input type

      if (property.type === "string" || property.multiwoven_secret) {
        return (
          <div key={key} className="mt-3">
            <label
              htmlFor={key}
              className="block text-sm font-medium leading-6 text-gray-900"
            >
              {property.title}
            </label>
            <div className="mt-2">
              <input
                type={inputType}
                name={key}
                placeholder={property.examples?.[0] || ""}
                className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-orange-600 sm:text-sm sm:leading-6"
              />
            </div>
            <p className="mt-2 text-sm text-gray-500">{property.description}</p>
          </div>
        );
      }

      if (property.type === "object" && property.oneOf) {
        const selectedCredentialType: Credentials = property.oneOf[0];

        const sortedProperties = Object.entries(
          selectedCredentialType.properties
        ).sort((a, b) => {
          return a[1].order - b[1].order;
        });

        return (
          <div key={key} className="mt-3 mb-8">
            <label
              htmlFor={key}
              className="block text-sm font-medium leading-6 text-gray-900"
            >
              {property.title}
            </label>
            {sortedProperties.map(([nestedKey, nestedProp]) =>
              renderInputField(nestedProp, nestedKey)
            )}
          </div>
        );
      }
    };

    // Sort the top-level properties based on 'order'
    const sortedPropertiesArray = Object.entries(
      data.connection_specification.properties
    ).sort((a, b) => {
      return a[1].order - b[1].order;
    });

    return (
      <>
        <form className="container mx-auto px-8 py-5">
          {sortedPropertiesArray.map(([key, property]) =>
            renderInputField(property, key)
          )}
          <a className="text-sm mt-4" href={data.documentation_url}>
            Click here to go to the docs
          </a>
          <br />
          <button
            type="submit"
            className="float-right rounded-md bg-orange-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-orange-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange-600"
          >
            Submit
          </button>
        </form>
      </>
    );
  } catch (error) {
    console.log(error);
    
    return (
      <>
        <h1>NO JSON</h1>
      </>
    );
  }
};
