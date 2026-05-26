package com.unievents.controller;

import com.unievents.dto.request.ScanRequest;
import com.unievents.dto.response.ScanResponse;
import com.unievents.service.ScanService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/scan")
@RequiredArgsConstructor
public class ScanController {

    private final ScanService scanService;

    @PostMapping
    @PreAuthorize("hasRole('CHECKER')")
    public ScanResponse scan(@RequestBody ScanRequest req) {
        return scanService.scan(req);
    }
}