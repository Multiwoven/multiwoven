import { Grid, GridItem } from "@chakra-ui/react"
import {
  canExpand,
  descriptionId,
  FormContextType,
  getTemplate,
  getUiOptions,
  ObjectFieldTemplateProps,
  RJSFSchema,
  StrictRJSFSchema,
  titleId,
} from "@rjsf/utils"
import DefaultObjectFieldTemplate from "@rjsf/chakra-ui/src/ObjectFieldTemplate"

export default function ObjectFieldTemplate<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>(props: ObjectFieldTemplateProps<T, S, F>) {
  const {
    description,
    title,
    properties,
    required,
    disabled,
    readonly,
    uiSchema,
    idSchema,
    schema,
    formData,
    onAddClick,
    registry,
  } = props

  const uiOptions = getUiOptions<T, S, F>(uiSchema)
  const TitleFieldTemplate = getTemplate<"TitleFieldTemplate", T, S, F>(
    "TitleFieldTemplate",
    registry,
    uiOptions
  )
  const DescriptionFieldTemplate = getTemplate<
    "DescriptionFieldTemplate",
    T,
    S,
    F
  >("DescriptionFieldTemplate", registry, uiOptions)

  const layout = uiOptions.layout as Record<string, string>

  if (layout?.display !== "grid" || !layout?.cols || !Array.isArray(layout?.colspans)) {
    return <DefaultObjectFieldTemplate {...props} />
  }

  // Button templates are not overridden in the uiSchema
  const {
    ButtonTemplates: { AddButton },
  } = registry.templates
  const gridTemplate = `repeat(${layout.cols}, 1fr)`

  return (
    <>
      {title && (
        <TitleFieldTemplate
          id={titleId<T>(idSchema)}
          title={title}
          required={required}
          schema={schema}
          uiSchema={uiSchema}
          registry={registry}
        />
      )}
      {description && (
        <DescriptionFieldTemplate
          id={descriptionId<T>(idSchema)}
          description={description}
          schema={schema}
          uiSchema={uiSchema}
          registry={registry}
        />
      )}
      <Grid templateColumns={gridTemplate} gap={6}>
        {properties.map((element, index) =>
          element.hidden ? (
            element.content
          ) : (
            <GridItem key={`${idSchema.$id}-${element.name}-${index}`} colSpan={Number(layout.colspans[index])}>
              {element.content}
            </GridItem>
          )
        )}
      </Grid>
      {canExpand<T, S, F>(schema, uiSchema, formData) && (
        <GridItem justifySelf="flex-end">
          <AddButton
            className="object-property-expand"
            onClick={onAddClick(schema)}
            disabled={disabled || readonly}
            uiSchema={uiSchema}
            registry={registry}
          />
        </GridItem>
      )}
    </>
  )
}
