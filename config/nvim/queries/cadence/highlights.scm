; Types - identifiers inside types should be @type, not @variable
(nominal_type (identifier) @type)
(type_annotation
  (nominal_type (identifier) @type))
(type_parameter (identifier) @type.parameter)
(intersection_type
  (nominal_type (identifier) @type))

; Built-in types (must come after generic type rules for priority)
((nominal_type (identifier) @type.builtin)
  (#match? @type.builtin "^(Int|Int8|Int16|Int32|Int64|Int128|Int256|UInt|UInt8|UInt16|UInt32|UInt64|UInt128|UInt256|Word8|Word16|Word32|Word64|Word128|Word256|Fix64|Fix128|Fix256|UFix64|UFix128|UFix256|String|Character|Bool|Address|Path|StoragePath|CapabilityPath|PublicPath|PrivatePath|Type|Void|Never|AnyStruct|AnyResource|AnyStructAttachment|AnyResourceAttachment|HashAlgorithm|SignatureAlgorithm|Account|Capability|Block)$"))

; Functions
(function_declaration
  (identifier) @function)
(init_declaration) @function.builtin
(destroy_declaration) @function.builtin

(invocation_expression
  (identifier) @function.call)
(invocation_expression
  (member_expression
    (identifier) @function.call))

; Parameters
(parameter
  (identifier) @variable.parameter)

; Fields and members
(member_expression
  (identifier) @property)
(optional_member_expression
  (identifier) @property)

; Declaration names
(composite_declaration
  (identifier) @type)
(interface_declaration
  (identifier) @type)
(attachment_declaration
  (identifier) @type)
(entitlement_declaration
  (identifier) @type)
(entitlement_mapping_declaration
  (identifier) @type)
(event_declaration (identifier) @type)
(enum_case_declaration
  (identifier) @constant)

; Variable declarations - the declared name
(variable_declaration
  (identifier) @variable)

; Literal expressions
(nil_expression) @constant.builtin
(bool_expression) @boolean
(integer_expression) @number
(fixed_point_expression) @number.float
(string_expression) @string
(string_content) @string
(escape_sequence) @string.escape
(string_interpolation) @punctuation.special

; Comments
(line_comment) @comment.line
(block_comment) @comment.block

; Statement keywords
(return_statement "return" @keyword.return)
(break_statement) @keyword.repeat
(continue_statement) @keyword.repeat

; Access modifiers
(access_modifier) @keyword.modifier
(access_modifier "pub" @keyword.modifier)
(access_modifier "priv" @keyword.modifier)
(access_modifier "access" @keyword.modifier)
(access_level) @keyword.modifier

; Function modifiers
(static_modifier) @keyword.modifier
(native_modifier) @keyword.modifier
(view_modifier) @keyword.modifier

; Authorization
(authorization "auth" @keyword.modifier)

; Self and result expressions
(self_expression) @variable.builtin
(result_expression) @variable.builtin

; Keywords in declarations
(function_declaration "fun" @keyword.function)
(function_expression "fun" @keyword.function)
(function_type "fun" @keyword.function)
(init_declaration "init" @keyword.function)
(destroy_declaration "destroy" @keyword.function)

(variable_declaration "let" @keyword.storage)
(variable_declaration "var" @keyword.storage)

(composite_declaration "struct" @keyword.type)
(composite_declaration "resource" @keyword.type)
(composite_declaration "contract" @keyword.type)
(composite_declaration "enum" @keyword.type)

(interface_declaration "struct" @keyword.type)
(interface_declaration "resource" @keyword.type)
(interface_declaration "contract" @keyword.type)
(interface_declaration "interface" @keyword.type)

(attachment_declaration "attachment" @keyword.type)
(attachment_declaration "for" @keyword)

(event_declaration "event" @keyword.type)

(entitlement_declaration "entitlement" @keyword.type)
(entitlement_mapping_declaration "entitlement" @keyword.type)
(entitlement_mapping_declaration "mapping" @keyword.type)

(import_declaration "import" @keyword.import)
(import_declaration "from" @keyword.import)

(transaction_declaration "transaction" @keyword)
(prepare_block "prepare" @keyword)
(execute_block "execute" @keyword)
(pre_conditions "pre" @keyword)
(post_conditions "post" @keyword)

(if_statement "if" @keyword.conditional)
(if_statement "else" @keyword.conditional)
(switch_statement "switch" @keyword.conditional)
(switch_case "case" @keyword.conditional)
(default_case "default" @keyword.conditional)

(while_statement "while" @keyword.repeat)
(for_statement "for" @keyword.repeat)
(for_statement "in" @keyword.repeat)

(create_expression "create" @keyword.operator)
(destroy_expression "destroy" @keyword.operator)
(emit_statement "emit" @keyword.operator)
(attach_expression "attach" @keyword.operator)
(attach_expression "to" @keyword.operator)
(remove_statement "remove" @keyword.operator)
(remove_statement "from" @keyword.operator)

(casting_expression "as" @keyword.operator)
(casting_expression "as?" @keyword.operator)
(casting_expression "as!" @keyword.operator)

; Operators
[
  "+"
  "-"
  "*"
  "/"
  "%"
  "=="
  "!="
  "<"
  "<="
  ">"
  ">="
  "&&"
  "||"
  "!"
  "&"
  "|"
  "^"
  "<<"
  ">>"
  "<-"
  "<-!"
  "<->"
  "->"
  "="
] @operator

; External scanner tokens (operators)
(nil_coalescing_op) @operator
(force_unwrap) @operator
(optional_marker) @operator

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "."
  ","
  ":"
  ";"
  "?."
  "@"
  "#"
] @punctuation.delimiter

; Path expressions
(path_expression) @string.special

; For-in loop variable
(for_statement
  (identifier) @variable)

; Expression identifiers (variables in expressions, not types)
(expression_statement
  (identifier) @variable)
(assignment_statement
  (identifier) @variable)
(binary_expression
  (identifier) @variable)
(unary_expression
  (identifier) @variable)
(conditional_expression
  (identifier) @variable)
(index_expression
  (identifier) @variable)
(argument
  (identifier) @variable)

; Invocation argument labels (must be after generic argument rule to take precedence)
(argument
  (identifier) @variable.parameter
  ":")
