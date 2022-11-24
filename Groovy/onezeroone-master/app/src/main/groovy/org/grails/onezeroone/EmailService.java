package org.grails.onezeroone;

import java.util.List;

public interface EmailService {
    void send(List<CourseSubscriber> subscriberList, Email email);
}
