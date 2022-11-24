package org.grails.onezeroone.plugins.gsp

import groovy.transform.CompileStatic

@CompileStatic
interface GspModel {
    String getTitle()
    String getBody()
    String getDay()
    String getGuideUrl()
}