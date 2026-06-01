package com.unievents.controller;

import com.unievents.dto.request.SubmitGameScoreRequest;
import com.unievents.dto.response.GameScoreResponse;
import com.unievents.dto.response.GameTypeStatsResponse;
import com.unievents.dto.response.LeaderboardEntryResponse;
import com.unievents.model.User;
import com.unievents.model.enums.GameType;
import com.unievents.service.GameScoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/games")
@RequiredArgsConstructor
public class GameScoreController {

    private final GameScoreService gameScoreService;

    @PostMapping("/scores")
    @PreAuthorize("hasRole('STUDENT')")
    public GameScoreResponse submitScore(
            @RequestBody SubmitGameScoreRequest req,
            @AuthenticationPrincipal User user) {
        return gameScoreService.submitScore(user, req);
    }

    @GetMapping("/stats/me")
    @PreAuthorize("hasRole('STUDENT')")
    public List<GameTypeStatsResponse> myStats(@AuthenticationPrincipal User user) {
        return gameScoreService.getMyStats(user);
    }

    @GetMapping("/leaderboard/{gameType}")
    @PreAuthorize("hasRole('STUDENT')")
    public List<LeaderboardEntryResponse> leaderboard(@PathVariable GameType gameType) {
        return gameScoreService.getLeaderboard(gameType);
    }

    @GetMapping("/events/{eventId}/leaderboard/{gameType}")
    @PreAuthorize("hasRole('STUDENT')")
    public List<LeaderboardEntryResponse> eventLeaderboard(
            @PathVariable UUID eventId,
            @PathVariable GameType gameType) {
        return gameScoreService.getEventLeaderboard(eventId, gameType);
    }
}
