package org.grails.onezeroone.plugins.gsp

import groovy.transform.CompileStatic

@CompileStatic
class GspModelImpl implements GspModel {
    String title
    String body
    String day
    String guideUrl

    Object asType(Class clazz) {
        if (clazz == Map) {
            return [title: title, body: body, day: day, guideUrl: guideUrl]
        }
        else {
            super.asType(clazz)
        }
    }
}
