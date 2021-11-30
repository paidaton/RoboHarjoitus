# -*- coding: utf-8 -*-
# +
*** Settings ***
Documentation     Tilaa uuden robotin RobotSpareBin Industries Inc.
...               Tallettaa the order HTML receipt as a PDF file.
...               Tallettaa the screenshot of the ordered robot.
...               Sulauttaa the screenshot of the robot to the PDF receipt.
...               Luo ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
#Library           RPA.Browser.Playwright
Library           RPA.Tables
Library           RPA.HTTP
#Library           RPA.Desktop
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault
Variables         variables.py
# -


*** Variables ***
#${ORDERS}  20
#${orderurl}     %{RPA_SECRET_URL}

*** Keywords ***
Open the robot order website
        Open Available Browser  https://robotsparebinindustries.com/#/robot-order


*** Keywords ***
Fill the form 
    [Arguments]    ${row}
    Click Element   css:#head[name="head"]
    Select From List By Value    css:#head[name="head"]  ${row}[Head]
    #Select Radio Button  mikä hemmetti muka käy tähän??????  ${row}[Body]
    Click Element    css:#id-body-${row}[Body]
    ${elem} = 	Get WebElement   class:form-control
    Input Text    ${elem}  ${row}[Legs]    True
    Input Text      address  ${row}[Address]

*** Keywords ***
Close the annoying modal
    #Click Button  css:button[name="OK"]
    Click Button  css:button[class="btn btn-dark"]

*** Keywords ***
Preview the robot
    Click Button  preview

*** Keywords ***
Submit the order
    Click Button  order
    Wait Until Page Contains Element    id:order-completion

*** Keywords ***
Go to order another robot
    Click Button  order-another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${kuitti}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${kuitti}    ${CURDIR}${/}output${/}robokuitti_${Order number}.pdf
    Return From Keyword  ${CURDIR}${/}output${/}robokuitti_${Order number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot    robot-preview-image   ${CURDIR}${/}output${/}robokuva_${Order number}.png
    Return From Keyword  ${CURDIR}${/}output${/}robokuva_${Order number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}  ${kuitti}
    Open PDF   ${kuitti}
    Add Watermark Image To PDF  ${screenshot}  ${kuitti}
    Close All Pdfs


*** Keywords ***
Create a ZIP file of the receipts
    [Arguments]   ${zipname} 
    Archive Folder With Zip  ${CURDIR}${/}output  ${zipname}

*** Keywords ***
Ask ZipFileName
    Add text input    ziptiedostonimi    label=KuittiZipinNimi
    ${zipname}=    Run dialog
    [Return]    ${zipname.ziptiedostonimi}

*** Keywords ***
Close the browser and remove useless files
    ${index}=    Set Variable    1
    Close Browser
        FOR    ${index}    IN RANGE    21
            Remove File    ${CURDIR}${/}output${/}robokuva_${index}.png
            Remove File    ${CURDIR}${/}output${/}robokuitti_${index}.pdf
            ${index}=    Evaluate    ${index} + 1
        END
    #Remove Directory  ${CURDIR}${/}output  recursive=True

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${zipname}=  Ask ZipFileName
    ${salesurl}=  Get Secret  secreturl
    Log  ${salesurl}
    Download    ${secret}[salesurl]    overwrite=True
    ${orders}=    Read table from CSV  orders.csv   header=True
    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Wait Until Keyword Succeeds    5x    5s   Submit the order  
         ${kuitti}=     Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${kuitti}
         Go to order another robot
    END
    Create a ZIP file of the receipts  ${zipname}
    [Teardown]    Close the browser and remove useless files

