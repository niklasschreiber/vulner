package org.grails.onezeroone;

import java.util.List;

public interface CourseSubscriberRepository {

    List<CourseSubscriber> findAllByDay(SubscriptionDay day);

    void moveToDay(List<CourseSubscriber> courseSubscriberList, SubscriptionDay day);

    CourseSubscriber save(CourseSubscriber subscriber);
}
