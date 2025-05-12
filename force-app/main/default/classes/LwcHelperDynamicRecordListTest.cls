@isTest
public class LwcHelperDynamicRecordListTest {
    @isTest
    static void testWrapperInstantiation() {
        // Config Wrapper
        LwcHelperDynamicRecordList.configWrapper config = new LwcHelperDynamicRecordList.configWrapper();
        config.keyFieldName = 'Id';

        // Column Wrapper
        LwcHelperDynamicRecordList.typeAttributesWrapper typeAttributes = new LwcHelperDynamicRecordList.typeAttributesWrapper();
        typeAttributes.tooltip = 'Test tooltip';
        typeAttributes.currencyCode = 'USD';
        typeAttributes.minimumFractionDigits = 2;
        typeAttributes.latitude = '37.7749';
        typeAttributes.longitude = '-122.4194';

        LwcHelperDynamicRecordList.columnWrapper column = new LwcHelperDynamicRecordList.columnWrapper('Name', 'Name', 'text');
        column.sortable = true;
        column.iconName = 'standard:account';
        column.hideLabel = false;
        column.typeAttributes = typeAttributes;

        // Row Wrapper
        LwcHelperDynamicRecordList.rowWrapper row = new LwcHelperDynamicRecordList.rowWrapper();
        row.fields.add(new LwcHelperDynamicRecordList.fieldWrapper('Name', 'Test Account'));
        row.fields.add(new LwcHelperDynamicRecordList.fieldWrapper('Industry', 'Technology'));

        // Main Data Wrapper
        LwcHelperDynamicRecordList.dataWrapper wrapper = new LwcHelperDynamicRecordList.dataWrapper();
        wrapper.config = config;
        wrapper.columns.add(column);
        wrapper.rows.add(row);

        // Assertions
        Assert.areEqual('Id', wrapper.config.keyFieldName, 'config.keyFieldName missing');
        Assert.areEqual('Name', wrapper.columns[0].label, 'columns[0].label missing');
        Assert.areEqual('Test Account', wrapper.rows[0].fields[0].value, 'field value incorrect');

        // Run validation
        List<String> validationErrors = LwcHelperDynamicRecordList.validateDataWrapper(wrapper);
        Assert.areEqual(validationErrors[0], 'Key field not present in row list: Id');

        wrapper.rows[0].fields.add(new LwcHelperDynamicRecordList.fieldWrapper('Id', '123'));
        List<String> validationErrorsPass = LwcHelperDynamicRecordList.validateDataWrapper(wrapper);

        Assert.areEqual(0, validationErrorsPass.size(), 'Validation should pass without errors.');

    }
}