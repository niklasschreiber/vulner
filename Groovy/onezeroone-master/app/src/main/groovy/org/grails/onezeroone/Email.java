package org.grails.onezeroone;

public interface Email {
    String getSubject();
    String getBody();
    String getFrom();
    String getTo();
    String getReplyTo();
}

