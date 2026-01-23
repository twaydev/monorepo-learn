<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

class IndexController
{
    #[Route("/", name: "index", methods: ["GET"])]
    public function index(): JsonResponse
    {
        return new JsonResponse([
            "message" => "Hello from PHP API Service 2",
            "path" => $_SERVER["REQUEST_URI"],
        ]);
    }
}
