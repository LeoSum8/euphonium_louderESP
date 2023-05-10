export enum PluginEntryType {
  Plugin = "plugin",
  System = "system",
  App = "app",
}

export interface PluginEntry {
  type: PluginEntryType;
  name: string;
  displayName: string;
}

export enum ConfigurationFieldType {
  GROUP = "group",
  TEXT = "text_field",
  SELECT = "select_field",
  NUMBER = "number_field",
  CHECKBOX = "checkbox_field",
  LINK_BUTTON = "link_button",
  MODAL_CONFIRM = "modal_confirm",
  BUTTON_FIELD = "button_field",
  MODAL_GROUP = "modal_group",
  PARAGRAPH = "paragraph",
}

export interface BaseConfigurationField {
  type: ConfigurationFieldType;
  id: string;
}

export interface ConfigurationFieldGroup extends BaseConfigurationField {
  type: ConfigurationFieldType.GROUP;
  label: string;
  children: ConfigurationField[];
}

export interface  ConfigurationModalGroup extends BaseConfigurationField {
  type: ConfigurationFieldType.MODAL_GROUP;
  children: ConfigurationField[];
  title: string;
  dismissable: boolean;
  global: boolean;
  priority: number;
}

export interface ConfigurationFieldLinkButton extends BaseConfigurationField {
  type: ConfigurationFieldType.LINK_BUTTON;
  label: string;
  link: string;
  placeholder: string;
}

export interface ConfigurationFieldWithStateKey extends BaseConfigurationField {
  stateKey: string;
}

export interface ConfigurationFieldText extends ConfigurationFieldWithStateKey {
  type: ConfigurationFieldType.TEXT;
  label: string;

  hint?: string;
  default?: string;
  hidden?: boolean;
}

export interface ConfigurationModalConfirmField extends ConfigurationFieldWithStateKey {
  type: ConfigurationFieldType.MODAL_CONFIRM;
  label: string;
  hint?: string;

  default?: string;
  okValue?: string;
  cancelValue?: string;
}

export interface ConfigurationNumberField extends ConfigurationFieldWithStateKey {
  type: ConfigurationFieldType.NUMBER;
  label: string;
  hint?: string;
  default?: number;
}

export interface CheckboxFieldConfiguration extends ConfigurationFieldWithStateKey {
  type: ConfigurationFieldType.CHECKBOX;
  label: string;
  hint?: string;
  default?: boolean;
}

export interface SelectFieldConfiguration extends ConfigurationFieldWithStateKey {
  type: ConfigurationFieldType.SELECT;
  label: string;
  values: string[];
  hint?: string;
  default?: string;
}

export interface ConfigurationButtonField extends ConfigurationFieldWithStateKey {
  type: ConfigurationFieldType.BUTTON_FIELD;
  label: string;
  hint?: string;
  buttonText?: string;
}

export interface ConfigurationParagraph extends ConfigurationFieldWithStateKey {
  type: ConfigurationFieldType.PARAGRAPH;
  text: string;
}

export type ConfigurationField =
  | ConfigurationFieldGroup
  | ConfigurationFieldText
  | SelectFieldConfiguration
  | ConfigurationNumberField
  | CheckboxFieldConfiguration
  | ConfigurationFieldLinkButton
  | ConfigurationModalConfirmField
  | ConfigurationButtonField
  | ConfigurationModalGroup
  | ConfigurationParagraph;

export interface PluginConfiguration {
  configSchema: ConfigurationField[];
  themeColor: string;
  displayName: string;
  state: any;
}
