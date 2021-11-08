*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           Collections
Library           MyLibrary
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Resource          keywords.robot
Variables         MyVariables.py

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    super_secret
    Open Available Browser    ${secret}[URL]

*** Keywords ***
Get orders
    [Arguments]    ${URL_order}
    Download    ${URL_order}    overwrite=True
    ${table_original}=    Read table from CSV    orders.csv
    [Return]    ${table_original}

*** Keywords ***
Close the annoying modal
    Click Button When Visible    //button[@class="btn btn-dark"]

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    preview

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds    5x    1s    Press the order button

*** Keywords ***
Press the order button
    Click Button    order
    Page Should Not Contain Element    order

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${row}
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt}    ${CURDIR}${/}output${/}order_receipt_${row}.pdf
    ${pdf1}=    Convert to string    ${CURDIR}${/}output${/}order_receipt_${row}.pdf
    [Return]    ${pdf1}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    locator=//div[@id="robot-preview-image"]    filename=${CURDIR}${/}output${/}screenshot.png
    ${screenshot_loc}=    Convert To String    ${CURDIR}${/}output${/}screenshot.png
    [Return]    ${screenshot_loc}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

*** Keywords ***
Go to order another robot
    Click Button    order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output    receipts.zip    include=*.pdf

*** Keywords ***
Ask for URL for orders
    Add text input    answer    label=Please enter the URL for the orders file
    ${URL_order}=    Run dialog
    [Return]    ${URL_order.answer}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${URL_order}=    Ask for URL for orders
    Open the robot order website
    ${orders}=    Get orders    ${URL_order}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
