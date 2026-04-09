import { useState, useEffect, useRef } from "react";
import { useQuery } from "@tanstack/react-query";
import { MapPin } from "lucide-react";
import { sitesApi, locationApi, equipmentApi, queryKeys } from "@/api/endpoints";

export default function LocationTracking() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const [siteId, setSiteId] = useState("");

  const sitesQuery = useQuery({
    queryKey: queryKeys.dispatch.sites({ size: 200 }),
    queryFn: () => sitesApi.getAll({ size: 200 }),
  });

  const personsQuery = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 200 }),
    queryFn: () => equipmentApi.getPersons({ size: 200 }),
  });

  const selectedSite = (sitesQuery.data?.content ?? []).find(
    (s) => s.id === siteId
  );

  // Initialize Leaflet map
  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    const loadLeaflet = async () => {
      const L = await import("leaflet");
      await import("leaflet/dist/leaflet.css");

      const map = L.map(mapRef.current!, {
        center: [37.5665, 126.978],
        zoom: 12,
      });

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "OpenStreetMap",
      }).addTo(map);

      mapInstanceRef.current = map;
    };

    loadLeaflet();

    return () => {
      mapInstanceRef.current?.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Update map when site selected
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map || !selectedSite) return;

    map.setView([selectedSite.latitude, selectedSite.longitude], 14);

    const L = (window as Record<string, unknown>).L as typeof import("leaflet");
    if (L) {
      L.marker([selectedSite.latitude, selectedSite.longitude])
        .addTo(map)
        .bindPopup(selectedSite.name);
    }
  }, [selectedSite]);

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">위치 추적</h1>

      <div className="flex items-center gap-4">
        <select
          value={siteId}
          onChange={(e) => setSiteId(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="">현장 선택</option>
          {(sitesQuery.data?.content ?? []).map((site) => (
            <option key={site.id} value={site.id}>
              {site.name}
            </option>
          ))}
        </select>
        {selectedSite && (
          <span className="flex items-center gap-1 text-sm text-gray-500">
            <MapPin className="h-4 w-4" />
            {selectedSite.address}
          </span>
        )}
      </div>

      <div
        ref={mapRef}
        className="h-[500px] w-full rounded-xl border border-gray-200"
      />

      {/* Worker list */}
      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">
          현장 작업 인원
        </h2>
        <div className="divide-y divide-gray-100">
          {(personsQuery.data?.content ?? []).slice(0, 10).map((person) => (
            <div
              key={person.id}
              className="flex items-center justify-between py-3"
            >
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {person.name}
                </p>
                <p className="text-xs text-gray-500">{person.role}</p>
              </div>
              <span
                className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                  person.active
                    ? "bg-green-100 text-green-800"
                    : "bg-gray-100 text-gray-600"
                }`}
              >
                {person.active ? "활성" : "비활성"}
              </span>
            </div>
          ))}
          {(personsQuery.data?.content ?? []).length === 0 && (
            <p className="py-4 text-center text-sm text-gray-500">
              작업 인원이 없습니다.
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
