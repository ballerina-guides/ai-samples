import ballerinax/googleapis.calendar;
import ballerinax/googleapis.gmail;

final gmail:Client gmailClient = check new gmail:Client(config = {
    auth: {refreshToken: googleRefreshToken, clientId, clientSecret, refreshUrl}
});

final calendar:Client calendarClient = check new (config = {
    auth: {clientId, clientSecret, refreshToken: googleRefreshToken, refreshUrl}
});
