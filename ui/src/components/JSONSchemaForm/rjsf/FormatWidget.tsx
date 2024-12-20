import { WidgetProps } from '@rjsf/utils';
import DataFormat from '@/components/DataFormat';

type FormatWidgetProps = WidgetProps & {
  formatType: 'request' | 'response';
};

const FormatWidget = ({ formatType, value, onChange, required }: FormatWidgetProps) => {
  return <DataFormat type={formatType} value={value} onChange={onChange} required={required} />;
};

export default FormatWidget;
