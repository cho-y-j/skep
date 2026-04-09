import { useEffect, useRef, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { MapPin, Navigation, Loader2 } from "lucide-react";
import toast from "react-hot-toast";
import { locationApi } from "@/api/endpoints";

export default function WorkerLocationTracking() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const [position, setPosition] = useState<{
    lat: number;
    lng: number;
  } | null>(null);

  const updateMutation = useMutation({
    mutationFn: (data: { latitude: number; longitude: number }) =>
      locationApi.update(data),
    onSuccess: () => {
      toast.success("위치가 업데이트되었습니다.");
    },
    onError: () => {
      toast.error("위치 업데이트에 실패했습니다.");
    },
  });

  // Get current position
  useEffect(() => {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setPosition({
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
        });
      },
      () => {
        setPosition({ lat: 37.5665, lng: 126.978 });
      }
    );
  }, []);

  // Initialize Leaflet map
  useEffect(() => {
    if (!mapRef.current || !position || mapInstanceRef.current) return;

    const loadLeaflet = async () => {
      const L = await import("leaflet");
      await import("leaflet/dist/leaflet.css");

      const map = L.map(mapRef.current!, {
        center: [position.lat, position.lng],
        zoom: 15,
      });

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "OpenStreetMap",
      }).addTo(map);

      L.marker([position.lat, position.lng])
        .addTo(map)
        .bindPopup("현재 위치")
        .openPopup();

      mapInstanceRef.current = map;
    };

    loadLeaflet();

    return () => {
      mapInstanceRef.current?.remove();
      mapInstanceRef.current = null;
    };
  }, [position]);

  const handleUpdateLocation = () => {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        setPosition({ lat, lng });
        updateMutation.mutate({ latitude: lat, longitude: lng });

        if (mapInstanceRef.current) {
          mapInstanceRef.current.setView([lat, lng], 15);
        }
      },
      () => {
        toast.error("위치 정보를 가져올 수 없습니다.");
      }
    );
  };

  return (
    <div className="space-y-4 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">위치 확인</h1>
        <button
          type="button"
          onClick={handleUpdateLocation}
          disabled={updateMutation.isPending}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors disabled:opacity-50"
        >
          {updateMutation.isPending ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Navigation className="h-4 w-4" />
          )}
          위치 업데이트
        </button>
      </div>

      {position && (
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <MapPin className="h-4 w-4" />
          <span>
            위도: {position.lat.toFixed(6)}, 경도: {position.lng.toFixed(6)}
          </span>
        </div>
      )}

      <div
        ref={mapRef}
        className="h-[500px] w-full rounded-xl border border-gray-200"
      />
    </div>
  );
}
