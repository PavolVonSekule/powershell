    <#
        .SYNOPSIS
        Imports data from csv file into SQL table.

        .DESCRIPTION
        Data for the import and table structure is defined for Microsoft 365 Product names and service plan identifiers for licensing (URL below).
        Script consists of two parts:
        - SQL part (T-SQL) creates type and (temp) table
        - PowerShell code that creates a DataTable, imports the data and inserts the data into SQL table

        .INPUTS
        You need to modify all input variables.

        .LINK
        Product names and service plan identifiers for licensing
        URL: https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference

    #>


##
#SQL part

## Create type
CREATE TYPE schema.ProductType AS TABLE (
    [Product_Display_Name] VARCHAR(200),
    [String_Id] VARCHAR(200),
    [GUID] UNIQUEIDENTIFIER,    
    [Service_Plan_Name] VARCHAR(200),
    [Service_Plan_Id] UNIQUEIDENTIFIER,
    [Service_Plans_Included_Friendly_Names] VARCHAR(200)
);

## Create temp table
CREATE TABLE schema.Table1 (
    [ID] [bigint] IDENTITY(1,1) NOT NULL,
    [Product_Display_Name] VARCHAR(200),
    [String_Id] VARCHAR(200),
    [GUID] UNIQUEIDENTIFIER,
    [Service_Plan_Name] VARCHAR(200),
    [Service_Plan_Id] UNIQUEIDENTIFIER,
    [Service_Plans_Included_Friendly_Names] VARCHAR(200)
);


##
#PowerShell part


# Define the path to the CSV file
$csvPath = "C:\Temp\licensing-service-plan-reference.csv"

# Read the CSV file
$csvData = Import-Csv -Path $csvPath

# Define the SQL Server connection string
$connectionString = "Server=AAAA-Dev.domain.it;Database=CCCC-DevDB;Integrated Security=True;"

# Define the table name
$tableName = "schema.Table1"

{
        
        [string]$columnName1 = "Product_Display_Name"                     #VARCHAR(200)
        [string]$columnName2 = "String_Id"                                #VARCHAR(200)
        [string]$columnName3 = "GUID"                                     #UNIQUEIDENTIFIER
        [string]$columnName4 = "Service_Plan_Name"                        #VARCHAR(200)
        [string]$columnName5 = "Service_Plan_Id"                          #UNIQUEIDENTIFIER
        [string]$columnName6 = "Service_Plans_Included_Friendly_Names"    #VARCHAR(200)

        [System.Data.DataTable]$csvTable = New-Object -TypeName "System.Data.DataTable"
        $csvTable.Columns.Add($columnName1, [System.Type]::GetType("System.String")) | Out-Null
        $csvTable.Columns.Add($columnName2, [System.Type]::GetType("System.String")) | Out-Null
        $csvTable.Columns.Add($columnName3, [System.Type]::GetType("System.Guid"))   | Out-Null
        $csvTable.Columns.Add($columnName4, [System.Type]::GetType("System.String")) | Out-Null
        $csvTable.Columns.Add($columnName5, [System.Type]::GetType("System.Guid"))   | Out-Null
        $csvTable.Columns.Add($columnName6, [System.Type]::GetType("System.String")) | Out-Null

        foreach ($csvLine in $csvData)
        {
            $row = $csvTable.NewRow()
            $row[$columnName1] = $csvLine.Product_Display_Name
            $row[$columnName2] = $csvLine.String_Id
            $row[$columnName3] = $csvLine.GUID
            $row[$columnName4] = $csvLine.Service_Plan_Name
            $row[$columnName5] = $csvLine.Service_Plan_Id
            $row[$columnName6] = $csvLine.Service_Plans_Included_Friendly_Names
            $csvTable.Rows.Add($row)
        }
        [System.Data.SqlClient.SqlConnection]$connection = New-Object -TypeName "System.Data.SqlClient.SqlConnection"
        $connection.ConnectionString = $ConnectionString

        [System.Data.SqlClient.SqlCommand]$command = $connection.CreateCommand()
        $command.CommandText = "INSERT INTO $tablename SELECT * FROM @data"
        $command.CommandType = [System.Data.CommandType]::Text

        [System.Data.SqlClient.SqlParameter] $parameter = $command.Parameters.Add("data", [System.Data.SqlDbType]::Structured)
        $parameter.TypeName = "ProductType"
        $parameter.Direction = [System.Data.ParameterDirection]::Input
        $parameter.Value = $csvTable

        try
        {
            $connection.Open()

            $command.ExecuteNonQuery()


        }
        catch
        {
            Write-Error -Message ("An error occured while querying the db: {$tableName}" + $PsItem.Exception.Message)
        }
        finally
        {

            $connection.Close()
        }
} 
