/*
    Copyright (c) 2017 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2018
* @group Utilities
* @description Object- and field-level security checks
*/
public with sharing class UTIL_Permissions {

    private final static String INSUFFICIENT_PERMISSION_MESSAGE = System.Label.flsError;

    private static UTIL_Permissions utilPermissionsInstance;

    /**
    * @description Returns static instance of this class.  Primarily used to facilitate
    * dependency injection in tests.
    * @return Instance of UTIL_Permission class.
    */
    public static UTIL_Permissions getInstance(){
        if (utilPermissionsInstance == null) {
            utilPermissionsInstance = new UTIL_Permissions();
        }
        return utilPermissionsInstance;
    }

    /**
    * @description Sets instance member variable holding instance of this class.  Primarily
    * used to facilitate dependency injection in tests.
    * @param utilPermissions An instance of the UTIL_Permissions class.
    */
    @TestVisible
    private static void setInstance(UTIL_Permissions utilPermissions){
        utilPermissionsInstance = utilPermissions;
    }

    /*** Object Level Security ***/

    /**
    * @description Determines whether the running user has read permissions on the given object
    * @param objectName the name of the object
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canRead(String objectName) {
        return canRead(objectName, true);
    }

    /**
    * @description Determines whether the running user has create permissions on the given object
    * @param objectName the name of the object
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canCreate(String objectName) {
        return canCreate(objectName, true);
    }

    /**
    * @description Determines whether the running user has update permissions on the given object
    * @param objectName the name of the object
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canUpdate(String objectName) {
        return canUpdate(objectName, true);
    }

    /**
    * @description Determines whether the running user has delete permissions on the given object
    * @param objectName the name of the object
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canDelete(String objectName) {
        return canDelete(objectName, true);
    }

    /**
    * @description Determines whether the running user has read permissions on the given object
    * @param objectName the name of the object
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canRead(String objectName, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(objectName).isAccessible()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    /**
    * @description Determines whether the running user has create permissions on the given object
    * @param objectName the name of the object
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canCreate(String objectName, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(objectName).isCreateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    /**
    * @description Determines whether the running user has update permissions on the given object
    * @param objectName the name of the object
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canUpdate(String objectName, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(objectName).isUpdateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    /**
    * @description Determines whether the running user has delete permissions on the given object
    * @param objectName the name of the object
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canDelete(String objectName, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(objectName).isDeletable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    /**
    * @description Determines whether the running user has delete permissions on the given object
    * This is an instance method which can be mocked.
    *
    * @param sObjectType Name of the sObject to check
    * @return returns boolean to indicate whether the user has permission
    */
    public Boolean canDelete(SObjectType sObjectType) {
        return UTIL_Describe.getObjectDescribe(sObjectType).isDeletable();
    }

    /*** Field Level Security ***/

    /**
    * @description Determines whether the running user has read permissions on the given object and field
    * @param objectName the name of the object
    * @param fieldName the name of the field
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canRead(String objectName, String fieldName) {
        return canRead(objectName, fieldName, true);
    }

    /**
    * @description Determines whether the running user has update permissions on the given object and field
    * @param objectName the name of the object
    * @param fieldName the name of the field
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canUpdate(String objectName, String fieldName) {
        return canUpdate(objectName, fieldName, true);
    }

    /**
    * @description Determines whether the running user has create permissions on the given object and field
    * @param objectName the name of the object
    * @param fieldName the name of the field
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canCreate(String objectName, String fieldName) {
        return canCreate(objectName, fieldName, true);
    }

    /**
    * @description Determines whether the running user has read permissions on the given object and field
    * @param objectName the name of the object
    * @param fieldName the name of the field
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canRead(String objectName, String fieldName, Boolean throwException) {
        DescribeFieldResult fieldResult = UTIL_Describe.getFieldDescribe(objectName, fieldName);
        return canRead(fieldResult, throwException);
    }

    /**
    * @description Determines whether the running user has create permissions on the given object and field
    * @param objectName the name of the object
    * @param fieldName the name of the field
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canCreate(String objectName, String fieldName, Boolean throwException) {
        DescribeFieldResult fieldResult = UTIL_Describe.getFieldDescribe(objectName, fieldName);
        return canCreate(fieldResult, throwException);
    }

    /**
    * @description Determines whether the running user has create permissions on the given object and field
    * @param objectName the name of the object
    * @param fieldName the name of the field
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public Boolean canCreateInstanced(String objectName, String fieldName, Boolean throwException) {
        DescribeFieldResult fieldResult = UTIL_Describe.getFieldDescribe(objectName, fieldName);
        return canCreate(fieldResult, throwException);
    }

    /**
    * @description Determines whether the running user has update permissions on the given object and field
    * @param objectName the name of the object
    * @param fieldName the name of the field
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception if not
    */
    public static Boolean canUpdate(String objectName, String fieldName, Boolean throwException) {
        DescribeFieldResult fieldResult = UTIL_Describe.getFieldDescribe(objectName, fieldName);
        return canUpdate(fieldResult, throwException);
    }

    /**
    * @description Determines whether the running user has read permissions on the DescribeFieldResult
    * @param fieldResult the DescribeFieldResult of the field to check
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canRead(DescribeFieldResult fieldResult) {
        return canRead(fieldResult, true);
    }

    /**
    * @description Determines whether the running user has create permissions on the DescribeFieldResult
    * @param fieldResult the DescribeFieldResult of the field to check
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canCreate(DescribeFieldResult fieldResult) {
        return canCreate(fieldResult, true);
    }

    /**
    * @description Determines whether the running user has update permissions on the DescribeFieldResult
    * @param fieldResult the DescribeFieldResult of the field to check
    * @return returns true if the user has permission; throws an exception not
    */
    public static Boolean canUpdate(DescribeFieldResult fieldResult) {
        return canUpdate(fieldResult, true);
    }

    /**
    * @description Determines whether the running user has read permissions on the given field
    * @param fieldResult the DescribeFieldResult of the field to check
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canRead(DescribeFieldResult fieldResult, Boolean throwException) {
        if (!fieldResult.isAccessible()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    /**
    * @description Determines whether the running user has create permissions on the given field
    * @param fieldResult the DescribeFieldResult of the field to check
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canCreate(DescribeFieldResult fieldResult, Boolean throwException) {
        if (!fieldResult.isCreateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    /**
    * @description Determines whether the running user has update permissions on the given field
    * @param fieldResult the DescribeFieldResult of the field to check
    * @param throwException indicates whether an exception should be thrown if the user doesn't have permission
    * @return returns boolean to indicate whether the user has permission; conditionally throws an exception not
    */
    public static Boolean canUpdate(DescribeFieldResult fieldResult, Boolean throwException) {
        if (!fieldResult.isUpdateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    /*******************************************************************************************************************
    * @description Determines whether the running user has read permissions on the sObject and fields provided
    *
    * @param sObjType the sObjectType to check read permissions
    * @param sObjFields the list of SObjectFields to check read permissions
    * @return Boolean true when the user has permissions for the SObjType and fields provided
    */
    public Boolean canRead(SObjectType sObjType, Set<SObjectField> sObjFields) {
        if (!canRead(sObjType)) {
            return false;
        }

        return canRead(SObjFields);
    }

    /***
    * @description Determines whether the running user has create permissions on the sObject and fields provided
    * @param sObjType the sObjectType to check create permissions
    * @param sObjFields the list of SObjectFields to check create permissions
    * @return Boolean true when the user has permissions for the SObjType and fields provided
    */
    public Boolean canCreate(SObjectType sObjType, Set<SObjectField> sObjFields) {
        if (!canCreate(sObjType)) {
            return false;
        }

        return canCreate(SObjFields);
    }


    /*******************************************************************************************************************
    * @description Determines whether the running user has read permissions on the sObject provided
    *
    * @param sObjType the sObjectType to check read permissions
    * @return Boolean true when the user has permissions for the SObjType provided
    */
    public Boolean canRead(SObjectType sObjType) {
        return canRead(String.valueOf(sObjType), false);
    }

    /*******************************************************************************************************************
    * @description Determines whether the running user has read permissions for the fields provided
    *
    * @param sObjFields the list of SObjectFields to check read permissions
    * @return Boolean true when the user has permissions for the SObjFields provided
    */
    public Boolean canRead(Set<SObjectField> sObjFields) {
        for (SObjectField field : sObjFields) {
            if (!canRead(field.getDescribe(), false)) {
                return false;
            }
        }

        return true;
    }

    /*******************************************************************************************************************
    * @description Determines whether the running user has create permissions for the fields
    * provided
    *
    * @param sObjFields the list of SObjectFields to check create permissions
    * @return Boolean true when the user has permissions for the SObjFields provided
    */
    public Boolean canCreate(Set<SObjectField> sObjFields) {
        for (SObjectField field : sObjFields) {
            if (!canCreate(field.getDescribe(), false)) {
                return false;
            }
        }

        return true;
    }

    /*******************************************************************************************************************
    * @description Determines whether the running user has create permissions for the object
    * provided
    *
    * @param sObjType the sObjectType to check update permissions
    * @return Boolean true when the user has permissions for the SObjType provided
    */
    public Boolean canCreate(SObjectType sObjType) {
        return canCreate(String.valueOf(sObjType), false);
    }

    /*******************************************************************************************************************
    * @description Determines whether the running user has update permissions on the sObject and fields provided
    *
    * @param sObjType the sObjectType to check update permissions
    * @param sObjFields the list of SObjectFields to check update permissions
    * @return Boolean true when the user has permissions for the SObjType and fields provided
    */
    public Boolean canUpdate(SObjectType sObjType, Set<SObjectField> sObjFields) {
        if (!canUpdate(sObjType)) {
            return false;
        }

        return canUpdate(SObjFields);
    }

    /*******************************************************************************************************************
    * @description Determines whether the running user has update permissions on the sObject provided
    *
    * @param sObjType the sObjectType to check update permissions
    * @return Boolean true when the user has permissions for the SObjType provided
    */
    public Boolean canUpdate(SObjectType sObjType) {
        return canUpdate(String.valueOf(sObjType), false);
    }

    /*******************************************************************************************************************
    * @description Determines whether the running user has update permissions for the fields provided
    *
    * @param sObjFields the list of SObjectFields to check update permissions
    * @return Boolean true when the user has permissions for the SObjFields provided
    */
    public Boolean canUpdate(Set<SObjectField> sObjFields) {
        for (SObjectField field : sObjFields) {
            if (!canUpdate(field.getDescribe(), false)) {
                return false;
            }
        }

        return true;
    }


    public Boolean canUpdate(Schema.SObjectType sObjectType, Set<String> fieldNames) {
        for (String fieldName: fieldNames) {
            if (!canUpdate(String.valueOf(sObjectType), fieldName, false)) {
                return false;
            }
        }
        return true;
    }

    public class InsufficientPermissionException extends Exception {}

}
