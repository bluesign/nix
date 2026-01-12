; Scopes
(function_declaration) @local.scope
(function_expression) @local.scope
(init_declaration) @local.scope
(composite_declaration) @local.scope
(interface_declaration) @local.scope
(attachment_declaration) @local.scope
(transaction_declaration) @local.scope
(block) @local.scope
(for_statement) @local.scope
(while_statement) @local.scope
(if_statement) @local.scope
(switch_case) @local.scope
(default_case) @local.scope

; Definitions - variables
(variable_declaration
  (identifier) @local.definition.var)

; Definitions - parameters (label and name)
(parameter
  .
  (identifier) @local.definition.parameter
  (identifier) @local.definition.parameter)

; Definitions - for loop variable(s)
(for_statement
  .
  (identifier) @local.definition.var)
(for_statement
  (identifier)
  .
  (identifier) @local.definition.var)

; Definitions - functions
(function_declaration
  (identifier) @local.definition.function)

; Definitions - types (structs, resources, contracts, enums)
(composite_declaration
  (identifier) @local.definition.type)

(interface_declaration
  (identifier) @local.definition.type)

(attachment_declaration
  (identifier) @local.definition.type)

(event_declaration
  (identifier) @local.definition.type)

(enum_case
  (identifier) @local.definition.enum)

; Definitions - entitlements
(entitlement_declaration
  (identifier) @local.definition.type)

(entitlement_mapping_declaration
  (identifier) @local.definition.type)

; Definitions - type parameters
(type_parameter
  (identifier) @local.definition.type)

; References - identifiers in expressions
(identifier) @local.reference
