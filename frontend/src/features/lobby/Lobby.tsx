import React, { useState, useCallback } from "react";
import { Link } from "react-router-dom";
import CreateRoomModal from "./CreateRoomModal";
import LobbyTable from "./LobbyTable";
import Button from "../../components/basic/Button";
import Container from "../../components/basic/Container";
import AdminContact from "../../components/AdminContact";

import useDataApi from "../../hooks/useDataApi";
import useChannel from "../../hooks/useChannel";
import useIsLoggedIn from "../../hooks/useIsLoggedIn";

interface Props {}

export const Lobby: React.FC = () => {
  const isLoggedIn = useIsLoggedIn();
  const [showModal, setShowModal] = useState(false);
  const { isLoading, isError, data, setData } = useDataApi<any>(
    "/be/api/rooms",
    null
  );

  const onChannelMessage = useCallback(
    (event, payload) => {
      if (event === "rooms_update" && payload.rooms != null) {
        setData({ data: payload.rooms });
      }
    },
    [setData]
  );

  useChannel("lobby:lobby", onChannelMessage);
  const rooms = data != null && data.data != null ? data.data : [];

  return (
    <Container>
      <div>
        <h1 className="mb-4">Lobby</h1>
        {isLoading && <div>Loading..</div>}
        {isError && <div>Error..</div>}
        <div className="mb-6">
          <h3 className="font-semibold mb-2">New Game</h3>
          <div>
            {isLoggedIn && (
              <Button isPrimary onClick={() => setShowModal(true)}>
                Create Room
              </Button>
            )}
            {!isLoggedIn && (
              <span className="text-gray-600 bg-gray-100 border rounded p-2">
                <Link to="/login" className="mr-1">
                  Log In
                </Link>
                To Create a Room
              </span>
            )}
          </div>
        </div>
        <div className="mb-6">
          <h3 className="font-semibold mb-2">Current Games</h3>
          <div className="mb-4">
            <LobbyTable rooms={rooms} />
          </div>
        </div>
        <h3 className="font-semibold mb-2">About</h3>
        <div className="max-w-lg">
          <p className="mb-2">
            StarSpades is a free online multiplayer spades game, inspired by the
            old yahoo games. It was just launched, and there are no bots to play
            with, so you might find it difficult to find an opponent. Invite
            your friends!
          </p>
          <p className="mb-2">
            If you have any suggestions or encounter any problems, please email
            me: <AdminContact />
          </p>
          <p>Last Update: 2019-11-16. Version: 0.1.0.</p>
        </div>
        <CreateRoomModal
          isOpen={showModal}
          closeModal={() => setShowModal(false)}
        />
      </div>
    </Container>
  );
};
export default Lobby;
