package com.skep.location.websocket;

import com.skep.location.dto.LocationRequest;
import com.skep.location.dto.LocationResponse;
import com.skep.location.service.LocationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
@Slf4j
public class LocationWebSocketHandler {

    private final LocationService locationService;

    @MessageMapping("/location/update")
    @SendTo("/topic/site/{siteId}")
    public LocationResponse updateLocationWebSocket(LocationRequest request, @DestinationVariable String siteId) {
        log.info("WebSocket location update received for worker: {}", request.getWorkerId());
        return locationService.updateLocation(request);
    }

}
